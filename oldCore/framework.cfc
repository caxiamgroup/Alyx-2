component output="no"
{
	this.sessionManagement = true;
	this.sessionTimeout = CreateTimeSpan(0, 4, 0, 0);

	this.mappings["/alyx"] = ReReplace(GetDirectoryFromPath(GetCurrentTemplatePath()), "(\\|/)core(\\|/){0,1}$", "");
	this.mappings["/alyx2"] = this.mappings["/alyx"]; //temporary fix


	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  **/
	public function onApplicationStart()
	{
		checkFramework();
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  **/
	public function onSessionStart()
	{
		checkFramework();
		setupSession();
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
		new cf9fixes.setting(showDebugOutput = false); //Adobe Coldfusion 9 Fix CFSETTING fix

		checkFramework();

		initAction();

		if (!StructKeyExists(request, "context"))
		{
			request.context = {};
		}

		restorePersistentContext();

		if (IsDefined("url"))
		{
			StructAppend(request.context, url);
		}
		if (IsDefined("form"))
		{
			StructAppend(request.context, form);
		}

		request.action = url.action;

		setupRequest();

		if (!StructKeyExists(request, "rendering"))
		{
			request.rendering = "html";
		}

		if (!StructKeyExists(request, "layout"))
		{
			request.layout = variables.framework.defaultLayout;
		}

		if (!StructKeyExists(request, "view"))
		{
			request.view = request.action;
		}

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
		local.content = "";

		try
		{
			local.content = view(action = request.action);

			if (Len(request.layout))
			{
				local.content = variables.layout(request.layout, local.content);
			}
			WriteOutput(local.content);
		}
		catch (MissingTopLevelView error)
		{
			onMissingView(error.extendedInfo);
		}
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method
	  **/
	public function onRequestEnd()
	{
	}

	/**
	  * DO NOT OVERRIDE.  Built-in Coldfusion Method. This handles the throws, callsLogException.
	  * @exception.hint Coldfusion passes a string/url to each of these functions
	  * @event.typeHint string
	  **/
	public function onError(exception = "", event = "")
	{
		if (StructKeyExists(arguments.exception, "rootCause"))
		{
			arguments.exception = arguments.exception.rootCause;
		}

		logException(
			exception = arguments.exception,
			event = arguments.event
		);

		if (!isDevEnvironment())
		{
			try
			{
				if (FileExists(application.controller.getViewPath("/error")&'.cfm'))
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
	  * This function was made to replace the default onApplicationStart method.
	  **/
	public function setupApplication()
	{
	}

	/**
	  * This function was made to replace the default onSessionStart method.
	  **/
	public function setupSession()
	{
	}

	/**
	  * This function was made to replace the default onRequestStart and onRequest methods.
	  **/
	public function setupRequest()
	{
	}

	/**
	  * In a situation where you have multiple developers, you may want to have special settings per person.
	  * With getEvironment, you can figure out exactly what evironment you are currently running on.
	  * By default, it looks to see if your URL contains localhost or a url provided from the getDevUrl function,
	  * and if so it's in dev mode, if not, it's in production mode.  Other functions use this to determine how alyx
	  * should be doing certain actions, specifically which settings files to read in and if the controllers and
	  * services need to be cached.  This function WAS intended to be extended and tweaked per project.
	  * @returns A String that represents the environment that is currently being used.  prod or dev
	  **/
	private function getEnvironment()
	{
		local.environment = "prod";

		local.devUrl = getDevUrl();

		if (cgi.http_host contains "localhost" || ( Len(local.devUrl) && cgi.http_host contains local.devUrl ))
		{
			local.environment = "dev";
		}

		return local.environment;
	}

	/**
	  * The purpose of this function is to get the URL.
	  * For example: If you have a vhost that was making the url of your dev version
	  * be myDevSite.google.com then you should make the devurl 'google.com'.
	  * This function is actually just going to get the setting from the settings file of what
	  * the url url is.
	  * @setting SETTINGS.DEV_URL
	  */
	private function getDevUrl()
	{
		return Application.controller.getSetting("DEV_URL", "");
	}

	/**
	  * This function checks to see if the environment is not production.
	  */
	private function isDevEnvironment()
	{
		return getEnvironment() != "prod";
	}

	/**
	  * The purpose of this function is for when there are errors coming in and the errors have to be sent to someone.
	  * This would take a list of emails.  This is actually just an alias to a setting.
	  * @setting SETTINGS.ERROR_EMAIL_RECIPIENTS
	  **/
	private function getErrorEmailRecipients()
	{
		return Application.controller.getSetting("ERROR_EMAIL_RECIPIENTS", "");
	}

	/**
	  * DO NOT OVERRIDE THIS FUNCTION.  This function inits variables.framework and sets it's default values onto it.
	  **/
	private function initFrameworkSettings()
	{
		if (!StructKeyExists(variables, "framework"))
		{
			variables.framework = {};
		}
		if (!StructKeyExists(variables.framework, "restartPassword"))
		{
			variables.framework.restartPassword = "1";
		}
		if (!StructKeyExists(variables.framework, "cacheServices"))
		{
			variables.framework.cacheServices = !isDevEnvironment();
		}
		if (!StructKeyExists(variables.framework, "cacheControllers"))
		{
			variables.framework.cacheControllers = !isDevEnvironment();
		}
		if (!StructKeyExists(variables.framework, "defaultLayout"))
		{
			variables.framework.defaultLayout = "main";
		}
	}

	/**
	  * Creates a new instance of the Controller object
	  **/
	private function createApplicationController()
	{
		return new controller(this);
	}

	/**
	  * Creates the scopes that we cache the controllers and services on, creates
	  * application.controller, loads settings, loads plugins, and calls setupApplication
	  **/
	private function initFramework()
	{
		local.framework = {};

		local.framework.controllers = {};
		local.framework.services = {};

		application.framework = local.framework;

		request.frameworkInitialized = true;

		application.controller = createApplicationController();

		loadSettings();

		initPlugins();

		setupApplication();

		application.initialized = Now();
	}

	/**
	  * This function was intended to be overridden.
	  * By default it loads framework settings, project settings, then environment settings
	  * in that order [loadFrameworkSettings(),loadProjectSettings(),loadEnvironmentSettings()].
	  * If you override this function make sure you call each of those functions to get the same result.
	  **/
	private function loadSettings()
	{
		loadSettingsFile("/alyx");
		loadSettingsFile();
		loadEnvironmentSettingsFile();
	}

	/**
	  * This loads the settings from a specified path.
	  * @path.hint If you want to reference your current project, do not change. To access alyx you would say "/alyx".
	  * @path.typeHint string
	  **/
	private function loadSettingsFile(path = "")
	{
		application.controller.loadSettingsFile("#arguments.path#/config/settings.cfm");
	}

	/**
	  * This loads the current environment settings that are built in your project from a specified path.
	  * @path.hint If you want to reference your current project, do not change. To access alyx you would say "/alyx".
	  * @path.typeHint string
	  **/
	private function loadEnvironmentSettingsFile(path = "")
	{
		local.environment = getEnvironment();
		if (Len(local.environment))
		{
			application.controller.loadSettingsFile("#arguments.path#/config/settings." & local.environment & ".cfm");
		}
	}

	/**
	  * This should be overridden.
	  * Put all application.controller.initPlugin functions in here.
	  * This allows for your init plugins to be done at one specified place.
	  **/
	private function initPlugins()
	{
	}

	/**
	  * This function checks internal logic to decide if the application needs to be restarted.
	  **/
	private function isRestartRequired()
	{
		return (
			! StructKeyExists(application, "initialized") ||
			(
				IsDefined("url.restart") &&
				url.restart == variables.framework.restartPassword &&
				! StructKeyExists(request, "frameworkInitialized")
			)
		);
	}

	/**
	  * This function turns the current request url into an action
	  **/
	private function initAction()
	{
		if (StructKeyExists(url, "action"))
		{
			url.action = ReReplace(Replace(ReReplace(url.action, ".cfm$", ""), "/", ".", "all"), "\.$", ".index");
		}
		else
		{
			// Turn file request into implicit action
			url.action = ListChangeDelims(ListFirst(cgi.script_name, "."), ".", "/");
		}

		if (ListLen(url.action, ".") == 1)
		{
			request.view = url.action;
			url.action = validateAction(url.action);
		}
	}

	/**
	  * This function ensures that all the default values exist on the framework before it
	  * tries to move forward, and if the application needs a restart then do so.
	  **/
	private function checkFramework()
	{
		initFrameworkSettings();

		if (isRestartRequired())
		{
			lock scope="application" type="exclusive" timeout="60"
			{
				if (isRestartRequired())
				{
					initFramework();
				}
			}
		}
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
	  * This function handles the caching and creation of the controllers within alyx.
	  * @action.hint Expects a dot-delimited string directing you to a controller with the the last in the list being the function on the controller
	  * @action.typeHint string
	  **/
	public function getController(required action)
	{
		local.controller = "";
		local.name = ListDeleteAt(arguments.action, ListLen(arguments.action, "."), ".");

		if (StructKeyExists(application.framework.controllers, local.name) && variables.framework.cacheControllers)
		{
			local.controller = application.framework.controllers[local.name];
		}
		else
		{
			lock name="framework.controllers.#local.name#" type="exclusive" timeout="20"
			{
				if (StructKeyExists(application.framework.controllers, local.name) && variables.framework.cacheControllers)
				{
					local.controller = application.framework.controllers[local.name];
				}
				else
				{
					local.controllerPath = Application.controller.getControllerPath(local.name);

					if (Len(local.controllerPath))
					{
						local.controller = CreateObject("component", local.controllerPath);
						if (StructKeyExists(local.controller, "init"))
						{
							local.controller.init();
						}

						if (variables.framework.cacheControllers)
						{
							application.framework.controllers[local.name] = local.controller;
						}
					}
				}
			}
		}

		return local.controller;
	}

	/**
	  * ensures that the action has at least 2 places with . delimited
	  *
	  * @action.hint Expects a dot-delimited string directing you to a controller with the the last in the list being the function on the controller
	  * @action.typeHint string
	  **/
	private function validateAction(action)
	{
		if (ListLen(arguments.action, ".") eq 1)
		{
			arguments.action = "general." & arguments.action;
		}

		return arguments.action;
	}


	/**
	  * runControllerMethod gets an instance of a controller based off of the action and tries to run 3 functions if they exist
	  * It will try to run the following functions:
	  * onBeforeControllerMethod(rc, vc, methodName), #methodName#(rc, vc), onAfterControllerMethod(rc, vc, methodName, methodReturn)
	  * This can be run publicly, although it's not always the best thing to do.
	  *
	  * @action.hint Expects a dot-delimited string directing you to a controller with the the last in the list being the function on the controller
	  * @action.typeHint string
	  * @vc.hint A struct to describe the View's Context.  If it's not defined it creates a new context for you
	  * @vc.typeHint struct
	  * @vc.defaultOverride StructNew()
	  * @exceptions.types 'Any'
	  */
	private function runControllerMethod(required action, vc = StructNew())
	{
		local.controller = getController(arguments.action);
		local.method = Replace(ListLast(arguments.action, "."), "-", "_", "all");
		arguments.vc.action = arguments.action;

		if (
			   !IsSimpleValue(local.controller)
			&& (
			      StructKeyExists(local.controller, local.method)
			   || StructKeyExists(local.controller, "onMissingMethod")
			   )
			)
		{
			try
			{
				local.defaultArguments = {
					rc = request.context,
					vc = arguments.vc
				};
				if (StructKeyExists(local.controller, "onBeforeControllerMethod"))
				{
					local.beforeArguments = {
						methodName = local.method
					};
					StructAppend(local.beforeArguments, local.defaultArguments);
					Evaluate("local.controller.onBeforeControllerMethod(ArgumentCollection = local.beforeArguments)");
				}
				local.controllerReturn = Evaluate("local.controller.#local.method#(ArgumentCollection = local.defaultArguments)");

				if (StructKeyExists(local.controller, "onAfterControllerMethod"))
				{
					local.afterArguments = {
						methodName = local.method,
						methodReturned = local.controllerReturn
					};
					StructAppend(local.afterArguments, local.defaultArguments);
					Evaluate("local.controller.onAfterControllerMethod(ArgumentCollection = local.afterArguments)");
				}
			}
			catch (Any error)
			{
				request.failedCfcName = getMetadata(local.controller).fullname;
				request.failedMethod = local.method;
				Throw(object = error);
			}
		}

		if (StructKeyExists(local, "controllerReturn"))
		{
			return local.controllerReturn;
		}
	}

	/**
	  * The view function runs the controllers for a view and will try to render itself correctly
	  **/
	private function view(path, action)
	{
		local.content = "";
		local.vc = {};

		if (StructKeyExists(arguments, "arguments"))
		{
			StructAppend(local.vc, arguments.arguments);
		}

		if (StructKeyExists(arguments, "action"))
		{
			arguments.action = validateAction(arguments.action);

			local.view = request.view;
			local.controllerResult = runControllerMethod(
				action = arguments.action,
				vc = local.vc
			);

			if (request.view != local.view)
			{
				local.temp = request.view;
				request.view = local.view;
				arguments.path = local.temp;
			}
			else
			{
				arguments.path = ListChangeDelims(arguments.action, "/", ".");
			}

			if (ListFirst(arguments.path, "/") eq "general")
			{
				arguments.path = ListRest(arguments.path, "/");
			}
		}
		else if (!StructKeyExists(arguments, "path"))
		{
			Throw(message = "Missing arguments");
		}

		local.path = arguments.path;

		local.content = Evaluate("renderAs#request.rendering#(ArgumentCollection = local)");

		return local.content;
	}

	/**
	  * This function is one of the many renderAs functions.
	  * This will handle all of our html requests (all non-xml or json requests)
	  **/
	private function renderAsHTML()
	{
		param name="request.viewDepth" default="0";

		++request.viewDepth;

		if (Len(arguments.path))
		{
			try
			{
				local.content = renderView(path = arguments.path, vc = arguments.vc);
			}
			catch (MissingInclude error)
			{
				if (request.viewDepth == 1)
				{
					Throw(type="MissingTopLevelView", extendedInfo="#error.missingFileName#");
				}
				else
				{
					Throw(object = error);
				}
			}
		}
		else if (StructKeyExists(arguments, "content"))
		{
			local.content = arguments.content;
		}

		--request.viewDepth;

		return local.content;
	}

	/**
	  * This function is one of the many renderAs functions.
	  * This will handle all of our json requests
	  **/
	private function renderAsJSON()
	{
		if(!StructKeyExists(arguments, "controllerResult"))
		{
			arguments.controllerResult = arguments.vc;
		}

		try
		{
			local.content = application.controller.renderContent(
				content = Serializejson(arguments.controllerResult),
				type = "application/json"
			);
		}
		catch (Any error)
		{
			Throw(message="The value returned from the controller is an invalid string. #cfcatch.message#");
		}

		return local.content;
	}

	/**
	  * This function is one of the many renderAs functions.
	  * This will handle all of our xml requests
	  **/
	private function renderAsXML()
	{
		try
		{
			local.content = application.controller.renderContent(
				content = arguments.controllerResult.toString(),
				type = "text/xml"
			);
		}
		catch (Any error)
		{
			Throw(message="The value returned from the controller is an invalid string. #error.message#");
		}

		return local.content;
	}

	/**
	  * This function actually goes to a view and saves it's content so it can be shown at a later date.  An important note to mention is that we append the VC to the variables scope so that views don't have to always say VC.myForm, instead they can just say myForm
	  * @vc.defaultOverride StructNew()
	  */
	private function renderView(required path, vc = StructNew())
	{
		var fw_out = "";
		var rc = request.context;

		StructAppend(variables, arguments.vc);

		saveContent variable="fw_out"
		{
			include "#application.controller.getViewPath(arguments.path)#.cfm";
		}

		return fw_out;
	}

	/**
	  * Similar to renderView function, layout actually gets the layout and renders out the page
	  **/
	private function layout(path, body)
	{
		var fw_out = "";
		var rc = request.context;

		savecontent variable="fw_out"
		{
			include "#application.controller.getLayoutPath(arguments.path)#.cfm";
		}

		return fw_out;
	}

	/**
	  * Redirect takes the place of CFLOCATION and allows you to pass the action of where you want to go to.
	  **/
	private function redirect(required action, persist = "", persistUrl = "", urlParams = "")
	{
		if (Len(arguments.persist))
		{
			storePersistentContext(arguments.persist);
		}

		if (Len(arguments.urlParams) || Len(arguments.persistUrl))
		{
			local.urlParams = ListToArray(ListLast(arguments.urlParams, "?"), "&");
		}

		if (Len(arguments.urlParams))
		{
			local.urlParamsLen = ArrayLen(local.urlParams);

			for (local.urlParamIndex = 1; local.urlParamIndex <= local.urlParamsLen; local.urlParamIndex++)
			{
				local.urlParam = local.urlParams[local.urlParamIndex];
				local.urlParamKey = ListFirst(local.urlParam, "=");
				localPersistsIndex = ListFindNocase(arguments.persistUrl, local.urlParamKey);

				if (localPersistsIndex && StructKeyExists(request.context, local.urlParamKey))
				{
					arguments.persistUrl = ListDeleteAt(arguments.persistUrl, localPersistsIndex);
				}
			}
		}

		if (Len(arguments.persistUrl))
		{
			local.persistUrl = ListToArray(arguments.persistUrl);

			for (local.currentPersistURL in local.persistUrl)
			{
				if (StructKeyExists(request.context, local.currentPersistURL))
				{
					ArrayPrepend(local.urlParams, local.currentPersistURL & "=" & request.context[local.currentPersistURL]);
				}
			}
		}

		if (StructKeyExists(local, "urlParams"))
		{
			arguments.urlParams = "?" & ArrayToList(local.urlParams, "&");
		}

		if (ListLen(arguments.action, ".") > 1)
		{
			if (ListFirst(arguments.action,".") == "general")
			{
				arguments.action = ListRest(arguments.action, ".");
			}

			arguments.action = "/" & ListChangeDelims(arguments.action, "/", ".");
		}

		if (Len(arguments.action) && Right(arguments.action, 1) != "/")
		{
			arguments.action &= ".cfm";
		}

		Location(url="#arguments.action##arguments.urlParams#", addtoken="no");
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
	  *	This function takes the keys and values that were stored from storePersistentContext and places them back into the RC
	  **/
	private function restorePersistentContext()
	{
		lock scope="session" type="exclusive" timeout="10"
		{
			if (StructKeyExists(session, "persistentContext"))
			{
				StructAppend(request.context, session.persistentContext);
				StructDelete(session, "persistentContext");
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

		if (isDevEnvironment())
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
}