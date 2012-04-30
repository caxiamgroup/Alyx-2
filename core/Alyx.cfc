component accessors="true" mappedsuperclass="true"
{
	property name="controllers" type="struct";
	property name="services"    type="struct";
	property name="plugins"     type="struct";
	property name="views"       type="struct";
	property name="layouts"     type="struct";
	property name="settings"    type="struct";

	//property name="helpers" type="struct";

	property name="restartPassword" type="string";
	property name="defaultLayout"   type="string";

	property name="cacheServices"    type="boolean";
	property name="cacheControllers" type="boolean";

	property name="mainEnvironment" type="string" default="prod";
	property name="developmentURL"  type="string" default="caxiamgroup.net";

	import alyx.tags.*;


	variables.PERSISTENT_CONTEXT_KEY = "persistentContext";

	variables.newError = createCustomException(
		type="ALYX.NONEXISTANT_HELPER_ERROR",
		MESSAGE = "The helper \1 does not exist in either the project location or Alyx.  Please figure this out ASAP!"
	);

	variables.NONEXISTANT_HELPER_ERROR = createCustomException(
		TYPE = "ALYX.NONEXISTANT_HELPER_ERROR",
		MESSAGE = "The helper \1 does not exist in either the project location or Alyx.  Please figure this out ASAP!"
	);

	public function createCustomException(type="", message="", detail="", code="", extendedInfo="")
	{
		try
		{
			local.exceptionClass = createObject("java", "coldfusion.runtime.CustomException");
		}
		catch("railo.commons.lang.ClassException" Error)
		{
			local.exceptionClass = createObject("java", "railo.runtime.exp.CustomTypeException");
		}

		return local.exceptionClass.init(
			arguments.type,
			arguments.message,
			arguments.detail,
			arguments.code,
			arguments.extendedInfo
		);
	}

	public function init()
	{
		//clearHelpers();
		//initHelpers();
		setPropertyDefaultValues(this);
		clearControllers();
		clearServices();
		clearPlugins();
		clearViews();
		clearLayouts();
		clearSettings();
		loadSettings();
		storeFrameworkSettings();
		initPlugins();
		request.frameworkInitialized = true;

		return this;
	}

	private function clearHelpers()
	{
		setHelpers({});
	}

	private function initHelpers()
	{
		initHelper(name="utility");
		initHelper(name="configuration");
		initHelper(name="caching");
		initHelper(name="environments");
		initHelper(name="pathing");
	}


	private function initHelper(required name)
	{
		local.helpers = getHelpers();
		local.helperPath = getHelperPath(ArgumentCollection = arguments);

		local.helper = CreateObject("component", local.helperPath).init(alyx = this);

		local.helpers[UCase(arguments.name)] = local.helper;

	}

	public function setPropertyDefaultValues(required object)
	{
		local.properties = getProperties(ArgumentCollection = arguments);
		for(local.property in local.properties)
		{
			if (StructKeyExists(local.property, "default"))
			{
				Evaluate("object.set#local.property.name#(local.property.default)");
			}
		}
	}

	private function getHelperPath(required name)
	{
		local.helperPath = "/helpers/" & arguments.name;

		if (!FileExists(ExpandPath(local.helperPath & ".cfc")))
		{
			local.helperPath = "/alyx" & local.helperPath;

			if (!FileExists(ExpandPath(local.helperPath & ".cfc")))
			{
				throw(
					type = variables.NONEXISTANT_HELPER_ERROR.TYPE,
					message = Replace(variables.NONEXISTANT_HELPER_ERROR.MESSAGE, "\1", UCase(arguments.name))
				);
			}
		}
		local.helperPath = ListChangeDelims(local.helperPath, ".", "/");

		return local.helperPath;
	}




/*----------------------------------- PUBLIC FUNCTIONS -----------------------------------*/

	public function getEnvironment()
	{
		local.environment = this.getMainEnvironment();
		local.devUrl = this.getDevelopmentURL();

		if (cgi.http_host contains "localhost" || ( !IsNull(local.devUrl) && Len(local.devUrl) && cgi.http_host contains local.devUrl ))
		{
			local.environment = "dev";
		}

		return local.environment;
	}


	public function isDevEnvironment()
	{
		return getEnvironment() != getMainEnvironment();
	}


	public function getSetting(required name, defaultValue = "")
	{
		return ( StructKeyExists(variables.settings, arguments.name) ) ? variables.settings[arguments.name] : arguments.defaultValue;
	}

	public function setupApplication()
	{
	}

	public function setupSession()
	{
	}

	public function setupRequestStart()
	{
		new setting(showDebugOutput = false);

		initActionFromURL();

		local.rc = getRC();

		restorePersistentContext();

		if (IsDefined("url"))
		{
			StructAppend(local.rc, url);
		}
		if (IsDefined("form"))
		{
			StructAppend(local.rc, form);
		}
	}

	public function setupRequest()
	{
	}

	public function getRC()
	{
		if (!StructKeyExists(request, "context"))
		{
			request.context = {};
		}
		return request.context;
	}

	public function renderRequest()
	{
		if (!StructKeyExists(request, "rendering"))
		{
			request.rendering = "html";
		}

		if (!StructKeyExists(request, "layout"))
		{
			request.layout = getDefaultLayout();
		}

		local.content = "";

		try
		{
			local.content = view(action = request.action);

			if (Len(request.layout))
			{
				local.content = layout(request.layout, local.content);
			}
			WriteOutput(local.content);
		}
		catch (MissingTopLevelView error)
		{
			onMissingView(error.extendedInfo);
		}
	}

	private function onMissingView(required path)
	{

		if (isDevEnvironment())
		{
			Throw(message="Missing View: #arguments.path#");
		}
		else
		{
			if(FileExists(ExpandPath("/404.cfm")))
			{
				include "/404.cfm";
			}
			else
			{
				Location(url="/index.cfm", addtoken="false");
			}
		}
	}

	public function getPlugin(required name)
	{
		return variables.plugins[arguments.name];
	}

	public function getService(required name)
	{
		local.service = "";

		if (StructKeyExists(variables.services, arguments.name) && variables.cacheServices)
		{
			local.service = variables.services[arguments.name];
		}
		else
		{
			lock name="variables.services.#arguments.name#" type="exclusive" timeout="20"
			{
				if (StructKeyExists(variables.services, arguments.name) && variables.framework.cacheServices)
				{
					local.service = application.framework.services[arguments.name];
				}
				else
				{
					local.servicePath = getServicePath(service = arguments.name);

					if (Len(local.servicePath))
					{
						local.service = CreateObject("component", local.servicePath).init(alyx = this);


						if (variables.cacheServices)
						{
							variables.services[arguments.name] = local.service;
						}
					}
				}
			}
		}

		return local.service;
	}

	private function getServicePath(required service)
	{
		var local = {};

		local.serviceComponentPath = "";
		local.path = ListChangeDelims(arguments.service, "/", ".");
		local.action = ListChangeDelims(arguments.service, ".", "/");
		local.componentName = ListLast(local.path, "/");
		local.serviceAction = local.action & "." & local.componentName & "Service";

		if (FileExists(ExpandPath("/models/" & local.path & "/" & local.componentName & "Service.cfc")))
		{
			local.serviceComponentPath = "/models." & local.serviceAction;
		}
		else if (StructKeyExists(variables.models, local.serviceAction))
		{
			local.serviceComponentPath = variables.models[local.serviceAction];
		}
		/*else if (ListLen(local.action, ".") > 1)
		{
			local.moduleName = ListFirst(arguments.service, ".");
			local.modules = getModules();

			if (StructKeyExists(local.modules, local.moduleName))
			{
				local.path = ListChangeDelims(ListRest(arguments.service,"."), "/", ".");
				if (FileExists(ExpandPath("/alyx/modules/" & local.modules[local.moduleName].name & "/models/" & local.path  & "/" & local.componentName & "Service.cfc")))
				{
					local.serviceComponentPath = "/alyx.modules." & local.modules[local.moduleName].name & ".models." & ListChangeDelims(local.path, ".", "/") & "." & local.componentName & "Service";
				}
			}
		}*/

		return local.serviceComponentPath;
	}

	private function getBasePath()
	{
		local.folderLocation = Replace(getBaseTemplateDirectory(), ExpandPath("/"), "");
		local.basePath = ReReplace(local.folderLocation, "[\/\\]$", "");
		if (Len(local.basePath))
		{
			local.basePath = "/" & local.basePath;
		}
		return local.basePath;
	}

	public function getViewPath(view)
	{
		arguments.view = ReReplace(arguments.view, "^/", "");

		local.view = getBasePath() & "/views/" & arguments.view;


		if (StructKeyExists(variables.views, arguments.view))
		{
			local.view = variables.views[arguments.view];
		}

		return local.view;
	}

	public function getLayoutPath(layout)
	{
		arguments.layout = ReReplace(arguments.layout, "^/", "");

		local.layout = getBasePath() & "/layouts/" & arguments.layout;

		if (StructKeyExists(variables.layouts, arguments.layout))
		{
			local.layout = variables.layouts[arguments.layout];
		}

		return local.layout;
	}

	public function isRestartRequired()
	{
		return (
			   IsDefined("url.restart")
			&& url.restart == getRestartPassword()
			&& !StructKeyExists(request, "frameworkInitialized")
		);
	}


/*----------------------------------- PRIVATE FUNCTIONS -----------------------------------*/

	private function clearControllers()
	{
		setControllers({});
	}


	private function clearServices()
	{
		setServices({});
	}


	private function clearPlugins()
	{
		setPlugins({});
	}

	private function clearViews()
	{
		setViews({});
	}

	private function clearLayouts()
	{
		setLayouts({});
	}


	private function clearSettings()
	{
		setSettings({});
	}


	private function storeFrameworkSettings()
	{
		setRestartPassword(getSetting(name = "restartPassword", defaultValue = "1"));
		setCacheServices(getSetting(name = "cacheServices", defaultValue = !isDevEnvironment()));
		setCacheControllers(getSetting(name = "cacheControllers", defaultValue = !isDevEnvironment()));
		setDefaultLayout(getSetting(name = "defaultLayout", defaultValue = "main"));
	}

	private function loadSettings()
	{
		loadSettingsFiles("/alyx");
		loadSettingsFiles();
	}

	private function loadSettingsFiles(path = "")
	{
		local.environment = getEnvironment();
		loadSettingsFile("#arguments.path#/config/settings.cfm");
		loadSettingsFile("#arguments.path#/config/settings." & local.environment & ".cfm");
	}


	private function loadSettingsFile(path)
	{
		local.settings = {};
		if (FileExists(ExpandPath(arguments.path)))
		{
			include "#arguments.path#";
		}
		StructAppend(getSettings(), local.settings);
	}


	private function initPlugins()
	{
		initPlugin(name = "snippets");
		initPlugin(name = "forms");
		initPlugin(name = "session");
		initPlugin(name = "utils");
		initPlugin(name = "profiler");
		initPlugin(name = "paginations");
	}


	private function initPlugin(name, cache = true)
	{
		if (!StructKeyExists(arguments, "key"))
		{
			arguments.key = arguments.name;
		}

		if (StructKeyExists(arguments, "path"))
		{
			local.path = arguments.path;
		}
		else
		{
			/*
				Check the following locations:
				    "/plugins/{environment}/plugin.cfc"
				    "/plugins/plugin.cfc"
				    "/alyx/plugins/plugin.cfc"
			*/
			local.path = "/alyx.plugins";
			local.environment = getEnvironment();
			local.basePath = getBasePath();
			if (Len(local.environment) && FileExists(ExpandPath(local.basePath & "/plugins/" & local.environment & "/" & arguments.name & "/" & arguments.name & ".cfc")))
			{
				local.path = local.basePath & "/plugins." & local.environment;
			}
			else if (FileExists(ExpandPath(local.basePath & "/plugins/"  & arguments.name & "/" & arguments.name & ".cfc")))
			{
				local.path = local.basePath & "/plugins";
			}
		}

		local.plugin = CreateObject("component", local.path & "." & arguments.name & "." & arguments.name);

		if (arguments.cache == true)
		{
			getPlugins()[arguments.key] = local.plugin;
		}

		if (StructKeyExists(local.plugin, "init"))
		{
			local.arguments = {
				alyx = this
			};

			if (StructKeyExists(arguments, "arguments"))
			{
				StructAppend(local.arguments, arguments.arguments);
			}
			local.plugin.init(argumentCollection = local.arguments);
		}

		return local.plugin;
	}

	public function arrayMerge(arrayTo, arrayFrom)
	{
		for (local.value in arguments.arrayFrom)
		{
			ArrayAppend(arguments.arrayTo, Duplicate(local.value));
		}
		return arguments.arrayTo;
	}

	private function getProperties(required object)
	{
		local.properties = [];
		local.metadata = {extends = getMetadata(arguments.object)};

		do
		{
			local.metadata = local.metadata.extends;

			local.properties = ArrayMerge(local.properties,getPropertiesFromMetadata(local.metadata));
		} while (StructKeyExists(local.metadata, "EXTENDS"));
		CreateObject("java", "java.util.Collections").reverse(local.properties);
		return local.properties;
	}

	private function getPropertiesFromMetadata(metadata)
	{
		local.properties = [];
		if (StructKeyExists(arguments.metadata, "properties"))
		{
			local.properties = CreateObject("java", "java.util.Arrays").asList(arguments.metadata.properties);
		}
		return local.properties;
	}

	private function getBaseTemplateDirectory()
	{
		return GetDirectoryFromPath(GetCurrentTemplatePath());
	}

	private function initActionFromURL()
	{
		if (StructKeyExists(url, "action"))
		{
			url.action = ReReplace(Replace(ReReplace(url.action, ".cfm$", ""), "/", ".", "all"), "\.$", ".index");
		}
		else
		{

			// Turn file request into implicit action
			local.currentPagePath = Replace(cgi.path_translated, getBaseTemplateDirectory(), "");

			url.action = ListChangeDelims(ListChangeDelims(ListFirst(local.currentPagePath, "."), "\", "/"),".", "\");
		}

		request.view = url.action;
		url.action = validateAction(url.action);
		request.action = url.action;
	}

	private function validateAction(action)
	{
		if (ListLen(arguments.action, ".") == 1)
		{
			arguments.action = "general." & arguments.action;
		}

		return arguments.action;
	}

	private function restorePersistentContext()
	{
		lock scope="session" type="exclusive" timeout="10"
		{
			if (StructKeyExists(session, variables.PERSISTENT_CONTEXT_KEY))
			{
				StructAppend(getRC(), session.persistentContext);
				StructDelete(session, variables.PERSISTENT_CONTEXT_KEY);
			}
		}
	}

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

			if (ListFirst(arguments.path, "/") == "general")
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
					rc = getRC(),
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

	private function getController(required action)
	{
		local.controller = "";
		local.name = ListDeleteAt(arguments.action, ListLen(arguments.action, "."), ".");

		if (variables.cacheControllers && StructKeyExists(variables.controllers, local.name))
		{
			local.controller = variables.controllers[local.name];
		}
		else
		{
			lock name="variables.controllers.#local.name#" type="exclusive" timeout="20"
			{
				if (variables.cacheControllers && StructKeyExists(variables.controllers, local.name))
				{
					local.controller = variables.controllers[local.name];
				}
				else
				{
					local.controllerPath = getControllerPath(local.name);

					if (Len(local.controllerPath))
					{

						local.controller = CreateObject("component", local.controllerPath);

						if (StructKeyExists(local.controller, "init"))
						{
							local.controller.init(alyx = this);
						}

						if (variables.cacheControllers)
						{
							variables.controllers[local.name] = local.controller;
						}
					}
				}
			}
		}

		return local.controller;
	}

	private function getControllerPath(name)
	{
		local.controllerPath = "";
		local.path = ListChangeDelims(arguments.name, "/", ".");
		local.basePath = getBasePath();

		if (FileExists(ExpandPath(local.basePath & "/controllers/" & local.path & ".cfc")))
		{
			if (Len(local.basePath))
			{
				local.controllerPath &= local.basePath & ".";
			}
			local.controllerPath &= "controllers." & arguments.name;
		}
		else if(StructKeyExists(variables.controllers, arguments.name))
		{
			local.controllerPath = variables.controllers[arguments.name];
		}
		/*else
		{
			for (local.module in getModules())
			{
				if (FileExists(ExpandPath("/alyx/modules/" & local.module & "/controllers/" & local.path & ".cfc")))
				{
					local.controllerPath = "/alyx.modules." & local.module & ".controllers." & arguments.name;
					break;
				}
			}
		}*/

		return local.controllerPath;
	}

	private function renderAsHTML()
	{
		param name="request.viewDepth" default="0";

		request.viewDepth++;

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
				Throw(object = error);
			}
		}
		else if (StructKeyExists(arguments, "content"))
		{
			local.content = arguments.content;
		}

		request.viewDepth--;

		return local.content;
	}

	private function renderAsJSON()
	{
		if(!StructKeyExists(arguments, "controllerResult"))
		{
			arguments.controllerResult = arguments.vc;
		}

		try
		{
			local.content = renderContent(
				content = Serializejson(arguments.controllerResult),
				type = "application/json"
			);
		}
		catch (Any error)
		{
			Throw(message="The value returned from the controller is an invalid string. #error.message#");
		}

		return local.content;
	}

	private function renderAsXML()
	{
		try
		{
			local.content = renderContent(
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

	private function renderView(required path, vc = StructNew())
	{
		var fw_out = "";
		var rc = getRC();

		StructAppend(variables, arguments.vc);

		saveContent variable="fw_out"
		{
			include "#getViewPath(arguments.path)#.cfm";
		}

		return fw_out;
	}


	private function layout(path, body)
	{
		var fw_out = "";
		var rc = getRC();

		savecontent variable="fw_out"
		{
			include "#getLayoutPath(arguments.path)#.cfm";
		}

		return fw_out;
	}

	public function redirect(required action, persist = "", persistUrl = "", urlParams = "")
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

}