component
{
	public function init(framework)
	{
		variables.framework = arguments.framework;
		initPersistentContainers();
		return this;
	}

	private function initPersistentContainers()
	{
		variables.settings = {};
		variables.plugins = {};
		variables.modules = {};
		variables.views = {};
		variables.layouts = {};
		variables.models = {};
		variables.controllers = {};
	}

	public function initPlugin(name)
	{
		if (not StructKeyExists(arguments, "key"))
		{
			arguments.key = arguments.name;
		}

		arguments.cache = true;

		getNewPlugin(argumentCollection = arguments);
	}

	private function getNewPlugin(name)
	{
		var local = {};

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

			if (Len(variables.framework.getEnvironment()) && FileExists(ExpandPath("/plugins/" & variables.framework.getEnvironment() & "/" & arguments.name & "/" & arguments.name & ".cfc")))
			{
				local.path = "/plugins." & variables.framework.getEnvironment();
			}
			else if (FileExists(ExpandPath("/plugins/"  & arguments.name & "/" & arguments.name & ".cfc")))
			{
				local.path = "/plugins";
			}
			else
			{
				local.path = "/alyx.plugins";
			}
		}

		local.plugin = CreateObject("component", local.path & "." & arguments.name & "." & arguments.name);

		if (StructKeyExists(arguments, "cache") && arguments.cache == true)
		{
			variables.plugins[arguments.key] = local.plugin;
		}

		if (StructKeyExists(local.plugin, "init"))
		{
			local.args = {};

			if (StructKeyExists(arguments, "arguments"))
			{
				StructAppend(local.args, arguments.arguments);
			}
			local.plugin.init(argumentCollection = local.args);
		}

		return local.plugin;
	}

	public function initModule(name)
	{
		var local = {};

		if (not StructKeyExists(arguments, "key"))
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
				    "/modules/name/module.cfc"
				    "/alyx/modules/name/module.cfc"
			*/

			if (FileExists(ExpandPath("/modules/" & arguments.name & "/module.cfc")))
			{
				local.path = "/modules." & arguments.name;
			}
			else
			{
				local.path = "/alyx.modules." & arguments.name;
			}
		}

		variables.modules[arguments.key] = CreateObject("component", local.path & ".module");

		if (StructKeyExists(variables.modules[arguments.key], "init"))
		{
			if (StructKeyExists(arguments, "arguments"))
			{
				variables.modules[arguments.key].init(argumentCollection = arguments.arguments);
			}
			else
			{
				variables.modules[arguments.key].init();
			}
		}

		scanCFMDirectory("/alyx/modules/" & arguments.name & "/views", arguments.name, variables.views);
		scanCFMDirectory("/modules/" & arguments.name & "/views", arguments.name, variables.views);
		scanCFMDirectory("/alyx/modules/" & arguments.name & "/layouts", arguments.name, variables.layouts);
		scanCFMDirectory("/modules/" & arguments.name & "/layouts", arguments.name, variables.layouts);
	}

	public function scanProjectDirectory(path)
	{
		var local = {};

		local.viewPath = arguments.path & "/views";
		local.controllerPath = arguments.path & "/controllers";
		local.modelsPath = arguments.path & "/models";
		local.layoutsPath = arguments.path & "/layouts";

		if(directoryExists(ExpandPath(local.viewPath)))
		{
			scanViewDirectory(local.viewPath);
		}

		if(directoryExists(ExpandPath(local.controllerPath)))
		{
			scanControllerDirectory(local.controllerPath);
		}

		if(directoryExists(ExpandPath(local.modelsPath)))
		{
			scanModelDirectory(local.modelsPath);
		}

		if(directoryExists(ExpandPath(local.layoutsPath)))
		{
			scanLayoutDirectory(local.layoutsPath);
		}
	}


	public function scanViewDirectory(path, name = "")
	{
		scanCFMDirectory(
			path = arguments.path,
			name = arguments.name,
			group = variables.views
		);

	}

	public function scanLayoutDirectory(path, name = "")
	{
		scanCFMDirectory(
			path = arguments.path,
			name = arguments.name,
			group = variables.layouts
		);
	}

	public function scanModelDirectory(path)
	{
		scanCFCDirectory(
			path = arguments.path,
			group = variables.models
		);
	}

	public function scanControllerDirectory(path)
	{
		scanCFCDirectory(
			path = arguments.path,
			group = variables.controllers
		);
	}

	private function scanCFCDirectory(path, group)
	{
		var local = {};

		local.path = ExpandPath(arguments.path);

		if (DirectoryExists(local.path))
		{
			local.CFCs = DirectoryList(local.path, true, "path", "*.cfc");
			local.numCFCs = ArrayLen(local.CFCs);
			local.action = Replace(arguments.path, "/", ".", "all");
			local.action = Replace(local.action, ".", "/",  "one");
			for (local.index = 1; local.index <= local.numCFCs; ++local.index)
			{
				local.file = local.CFCs[local.index];
				local.file = Replace(local.file, local.path, "");
				local.file = ReReplace(local.file, "\.cfc$", "");
				local.file = Replace(local.file, "\", "/", "all");
				local.file = Replace(local.file, "/", ".", "all");
				local.key = Replace(local.file, ".", "",  "one");

				arguments.group[local.key] = local.action & local.file;
			}
		}

	}

	private function scanCFMDirectory(path, name, group)
	{
		var local = {};

		local.path = ExpandPath(arguments.path);

		if (DirectoryExists(local.path))
		{
			local.CFMs = DirectoryList(local.path, true, "path", "*.cfm");
			local.numCFMs = ArrayLen(local.CFMs);

			for (local.index = 1; local.index <= local.numCFMs; ++local.index)
			{
				local.file = local.CFMs[local.index];
				local.file = Replace(local.file, local.path, "");
				local.file = ReReplace(local.file, "\.cfm$", "");
				local.file = Replace(local.file, "\", "/", "all");
				if (!Len(arguments.name))
				{
					local.key = Replace(local.file, "/", "", "one");
					arguments.group[local.key] = arguments.path & local.file;
				}
				else
				{
					arguments.group[arguments.name & local.file] = arguments.path & local.file;
				}
			}
		}
	}

	public function getModelPath(model)
	{
		var local = {};

		local.serviceComponentPath = "";
		local.path = ListChangeDelims(arguments.model, "/", ".");
		local.action = ListChangeDelims(arguments.model, ".", "/");
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
		else if (ListLen(local.action, ".") > 1)
		{
			local.moduleName = ListFirst(arguments.model, ".");
			local.modules = application.controller.getModules();

			if (StructKeyExists(local.modules, local.moduleName))
			{
				local.path = ListChangeDelims(ListRest(arguments.model,"."), "/", ".");
				if (FileExists(ExpandPath("/alyx/modules/" & local.modules[local.moduleName].name & "/models/" & local.path  & "/" & local.componentName & "Service.cfc")))
				{
					local.serviceComponentPath = "/alyx.modules." & local.modules[local.moduleName].name & ".models." & ListChangeDelims(local.path, ".", "/") & "." & local.componentName & "Service";
				}
			}
		}

		return local.serviceComponentPath;
	}

	public function getViewPath(view)
	{
		arguments.view = ReReplace(arguments.view, "^/", "");
		if (StructKeyExists(variables.views, arguments.view))
		{
			return variables.views[arguments.view];
		}

		return "/views/" & arguments.view;
	}

	public function getLayoutPath(layout)
	{
		arguments.layout = ReReplace(arguments.layout, "^/", "");

		if (StructKeyExists(variables.layouts, arguments.layout))
		{
			return variables.layouts[arguments.layout];
		}

		return "/layouts/" & arguments.layout;
	}

	public function getSettings()
	{
		return variables.settings;
	}

	public function getContext()
	{
		return request.context;
	}

	public function redirect()
	{
		variables.framework.redirect(argumentCollection = arguments);
	}

	public function getAction()
	{
		return request.action;
	}

	public function runControllerMethod()
	{
		variables.framework.runControllerMethod(argumentCollection = arguments);
	}

	public function getEnvironment()
	{
		return variables.framework.getEnvironment();
	}

	public function isDevEnvironment()
	{
		return variables.framework.isDevEnvironment();
	}

	public function persist(keys)
	{
		variables.framework.storePersistentContext(arguments.keys);
	}

	public function getPlugin(name)
	{
		return variables.plugins[arguments.name];
	}

	public function getService()
	{
		return variables.framework.getService(argumentCollection = arguments);
	}

	public function getModule(name)
	{
		return variables.modules[arguments.name];
	}

	public function getModules()
	{
		return variables.modules;
	}

	public function logException(exception)
	{
		variables.framework.logException(argumentCollection = arguments);
	}

	public function setClientMaintenanceMode(value)
	{
		variables.clientMaintenanceMode = arguments.value;
	}

	public function getClientMaintenanceMode()
	{
		return variables.clientMaintenanceMode;
	}


	public function loadSettingsFile(path)
	{
		var settings = {};
		if (FileExists(ExpandPath(arguments.path)))
		{
			include "#arguments.path#";
		}
		StructAppend(variables.settings, settings);
	}

	public function getSetting(name, defaultValue="")
	{
		return (StructKeyExists(variables.settings, arguments.name))?variables.settings[arguments.name]:arguments.defaultValue;
	}

	public function renderContent(required content, type="text/html")
	{
		setContentType(arguments.type);
		writeOutput(arguments.content);
		abort;
	}

	private function setContentType(type="text/html")
	{
		getPageContext().getResponse().getResponse().setContentType(arguments.type);
	}


}