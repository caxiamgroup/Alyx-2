component
{
	this.sessionManagement = true;
	this.sessionTimeout = CreateTimeSpan(0, 4, 0, 0);

	this.mappings["/alyx"] = ReReplace(GetDirectoryFromPath(GetCurrentTemplatePath()), "(\\|/)core(\\|/){0,1}$", "");
	this.mappings["/alyx2"] = this.mappings["/alyx"]; //temporary fix

	this.ALYX_KEY = "ALYX";

	private function getAlyx()
	{

		if (!doesAlyxExistOnFrameworkScope())
		{
			setAlyxOnFrameworkScope(alyx = createAlyx());
		}
		return getAlyxFromFrameworkScope();
	}

	private function createAlyx()
	{
		try
		{
			if (FileExists(ExpandPath("/Alyx.cfc")))
			{
				local.alyx = CreateObject("component", "/Alyx");
				if (StructKeyExists(local.alyx, "init"))
				{
					local.alyx.init();
				}
				return local.alyx;
			}
			return new Alyx();
		}
		catch (Any error)
		{
			writeOutput(renderException(exception = error, event = "ALYX"));
			abort;
		}
	}

	private function destroyAlyx()
	{
		StructDelete(getFrameworkScope(), this.ALYX_KEY);
	}

	private function getFrameworkScope()
	{
		return Application;
	}

	private function doesAlyxExistOnFrameworkScope()
	{
		return StructKeyExists(getFrameworkScope(), this.ALYX_KEY) && !IsSimpleValue(getAlyxFromFrameworkScope());
	}

	private function setAlyxOnFrameworkScope(required alyx)
	{
		getFrameworkScope()[this.ALYX_KEY] = arguments.alyx;
	}

	private function getAlyxFromFrameworkScope()
	{
		return getFrameworkScope()[this.ALYX_KEY];
	}

	/**
	  * This function ensures that all the default values exist on the framework before it
	  * tries to move forward, and if the application needs a restart then do so.
	  **/
	private function checkFramework()
	{
		local.alyx = getAlyx();

		if (local.alyx.isRestartRequired())
		{
			lock scope="Application" type="exclusive" timeout="60"
			{
				if (local.alyx.isRestartRequired())
				{
					if (local.alyx.isDevEnvironment())
					{
						destroyAlyx();
						checkFramework();
					}
					else
					{
						local.alyx.init();
					}
				}
			}
		}
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  **/
	public function onApplicationStart()
	{
		checkFramework();
		getAlyx().setupApplication();
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  **/
	public function onSessionStart()
	{
		checkFramework();
		getAlyx().setupSession();
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  * @targetPage.hint Coldfusion passes a string/url to each of these functions
	  * @targetPage.typeHint string
	  **/
	public function onMissingTemplate(targetPage)
	{
		onRequestStart(targetPage);
		onRequest(targetPage);
		onRequestEnd();
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  * @targetPage.hint Coldfusion passes a string/url to each of these functions
	  * @targetPage.typeHint string
	  **/
	public function onRequestStart(targetPage)
	{
		checkFramework();
		local.alyx = getAlyx();
		local.alyx.setupRequestStart();
		local.alyx.setupRequest();
		if (Right(arguments.targetPage, 4) == ".cfc")
		{
			StructDelete(this, "onRequest");
			StructDelete(variables, "onRequest");
		}
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  * @targetPage.hint Coldfusion passes a string/url to each of these functions
	  * @targetPage.typeHint string
	  **/
	public function onRequest(targetPage)
	{
		getAlyx().renderRequest();
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  **/
	public function onRequestEnd()
	{
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method. This handles the throws, calls LogException.
	  * @exception.hint Coldfusion passes a string/url to each of these functions
	  * @event.typeHint string
	  **/
	public function onError(exception = "", event = "")
	{
		local.alyx = getAlyx();
		if (StructKeyExists(arguments.exception, "rootCause"))
		{
			arguments.exception = arguments.exception.rootCause;
		}

		logException(
			exception = arguments.exception,
			event = arguments.event
		);

		if (!local.alyx.isDevEnvironment())
		{
			try
			{
				if (FileExists(local.alyx.getViewPath("/error")&'.cfm'))
				{
					request.context.exception = arguments.exception;
					redirect(action = "general.error", persist = "exception");
				}
				else
				{
					WriteOutput("An error has occurred. Please try again in a few minutes.");
					abort;
				}
			}
			catch (Any error)
			{
				Throw(object = error);
			}
		}
	}


	/**
	  * The purpose of this function is for when there are errors coming in and the errors have to be sent to someone.
	  * This would take a list of emails.  This is actually just an alias to a setting.
	  * @setting SETTINGS.ERROR_EMAIL_RECIPIENTS
	  **/
	private function getErrorEmailRecipients()
	{
		return getAlyx().getSetting("ERROR_EMAIL_RECIPIENTS", "");
	}


	/**
	  * This function handles the caching and creation of the services within alyx.
	  * @name.hint Expects the name of a service that it can find.
	  * @name.typeHint string
	  **/
	private function getService(required name)
	{
		local.service = "";

		if (StructKeyExists(application.framework.services, arguments.name) && variables.framework.cacheServices)
		{
			local.service = application.framework.services[arguments.name];
		}
		else
		{
			lock name="framework.services.#arguments.name#" type="exclusive" timeout="20"
			{
				if (StructKeyExists(application.framework.services, arguments.name) && variables.framework.cacheServices)
				{
					local.service = application.framework.services[arguments.name];
				}
				else
				{
					local.servicePath = application.controller.getModelPath(model = arguments.name);

					if (Len(local.servicePath))
					{
						local.service = CreateObject("component", local.servicePath);
						if (StructKeyExists(local.service, "init"))
						{
							local.service.init();
						}

						if (variables.framework.cacheServices)
						{
							application.framework.services[arguments.name] = local.service;
						}
					}
				}
			}
		}

		return local.service;
	}



	/**
	  * This function stores a list of keys from the RC into the Session.
	  **/
	private function storePersistentContext(required keys)
	{
		lock scope="session" type="exclusive" timeout="10"
		{
			if (!StructKeyExists(session, "persistentContext"))
			{
				session.persistentContext = {};
			}

			for (local.key in ListToArray(arguments.keys))
			{
				if (StructKeyExists(request.context, local.key))
				{
					session.persistentContext[local.key] = request.context[local.key];
				}
			}
		}
	}



	/**
	  * This handles when there is a view not included in the views folder.
	  * If it's in the dev environment, it throws errors.
	  * If it's in production it will try to find 404.cfm in the root.
	  * If it cannot find 404.cfm then it redirects to the index.cfm
	  **/
	private function onMissingView(required action)
	{
		if (isDevEnvironment())
		{
			Throw(message = "Missing View: #arguments.action#");
		}
		else
		{
			if (FileExists(application.controller.getViewPath("/404")&'.cfm'))
			{
				request.context.404Action = arguments.action;
				redirect(action = "general.404", persist="404Action");
			}
			else
			{
				redirect(action = "general.index");
			}
		}
	}

	/**
	  * If in dev environment it will dump the exception
	  * If in Production environment it will send an email to emailRecipients.
	  * @exception.hint either a CFCATCH object or the error coming from a cfcatch
	  **/
	private function logException(required exception, event = "")
	{
		local.alyx = getAlyx();

		local.output = renderException(argumentCollection = arguments);

		if (local.alyx.isDevEnvironment())
		{
			WriteOutput(local.output);
			abort;
		}
		else if (Len(getErrorEmailRecipients()))
		{
			new Mail().send(
				from = "errors@#cgi.server_name#",
				to = "#getErrorEmailRecipients()#",
				subject = "Website Error (#cgi.server_name#)",
				type = "html",
				body = local.output
			);
		}
	}

	private function renderException(required exception, event = "")
	{
		local.cgi = Duplicate(cgi);

		if (StructKeyExists(local.cgi, "auth_password"))
		{
			StructDelete(local.cgi, "auth_password");
		}

		if (StructKeyExists(local.cgi, "auth_user"))
		{
			StructDelete(local.cgi, "auth_user");
		}

		savecontent variable="local.output"
		{
			WriteOutput("<h1>Exception in #(Len(arguments.event))?arguments.event:''#");
			WriteOutput("(#(StructKeyExists(request, "action"))?request.action:''#)</h1>");
			WriteOutput("<h2>#arguments.exception.message#</h2>");
			WriteOutput("<p>#arguments.exception.detail#</p>");
			WriteDump(arguments.exception);
			WriteDump(var = local.cgi, label = "CGI");
			WriteDump(var = form, label = "FORM");
			if (IsDefined("session.sessionID"))
			{
				WriteDump(var = "session.sessionID", label = "SESSIONID");
			}
		}
		return local.output;
	}
}