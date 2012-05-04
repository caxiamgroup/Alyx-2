component name="baseService" output="no" hint="Abstract base class for model services"
{
	public function init(required alyx)
	{
		variables.alyx = arguments.alyx;

		variables.NONEXISTANT_FUNCTION_ON_SERVICE_ERROR = variables.alyx.createCustomException(
			TYPE = "CONTROLLER.COMMON.NONEXISTANT_FUNCTION_ON_SERVICE_ERROR",
			MESSAGE = "The function you are trying to call on the service does not exist"
		);
		local.serviceName = getMetadata(this).name;
		variables.beanName = Left(local.serviceName, (Len(local.serviceName)-7));

		variables.methodPaths = {};
		initServiceMethodPaths();

		return this;
	}

	public function onMissingMethod(required missingMethodName, required missingMethodArguments)
	{
		if (StructKeyExists(variables.methodPaths, arguments.missingMethodName))
		{
			local.service = getService(variables.methodPaths[arguments.missingMethodName]);
			try
			{
				return Evaluate("local.service.#arguments.missingMethodName#(argumentCollection = arguments.missingMethodArguments)");
			}
			catch (Any e)
			{
				Throw(message="There was a problem while trying to invoke #arguments.missingMethodName# in the #variables.methodPaths[arguments.missingMethodName]# service");
			}
		}
	}

	private function initServiceMethodPaths()
	{
		mapServiceMethodPath(getMetadata(this));
	}

	private function mapServiceMethodPath(serviceMetadata)
	{
		for(local.path in DirectoryList(GetDirectoryFromPath(arguments.serviceMetadata.path), true))
		{
			if(DirectoryExists(local.path))
			{
				local.servicePath = ListChangeDelims(ReReplace(local.path, ".+(\\models|\/models)", ""), "/", "\");
				local.service = getService(local.servicePath);

				if(!isSimplevalue(local.service))
				{
					local.serviceMetaData = getMetadata(local.service);

					if(StructKeyExists(local.serviceMetaData, "functions"))
					{
						mapServiceMethodsPath(
							path = local.servicePath,
							serviceMetaData = local.serviceMetaData
						);

					}
				}
			}
		}

		if(StructKeyExists(arguments.serviceMetadata, "extends") AND NOT arguments.serviceMetadata.extends.name CONTAINS "baseService")
		{
			mapServiceMethodPath(arguments.serviceMetadata.Extends);
		}
	}

	private function mapServiceMethodsPath(path, serviceMetaData)
	{
		local.invalidMethodNames = "init,create";
		local.methodCount = ArrayLen(arguments.serviceMetaData.functions);
		for(local.methodIndex = 1; local.methodIndex <= local.methodCount; ++local.methodIndex)
		{
			local.method = arguments.serviceMetaData.functions[local.methodIndex];
			if(ListFind(local.invalidMethodNames, local.method.name) || StructKeyExists(variables.methodPaths, local.method.name)) continue;
			variables.methodPaths[local.method.name] = arguments.path;
		}

		if(StructKeyExists(arguments.serviceMetadata, "extends") AND NOT arguments.serviceMetadata.extends.name CONTAINS "baseService")
		{
			mapServiceMethodsPath(arguments.path, arguments.serviceMetadata.extends);
		}
	}

	public function getPlugin(name)
	{
		return variables.alyx.getPlugin(arguments.name);
	}

	public function getService(name)
	{
		return variables.alyx.getService(arguments.name);
	}

	public function create()
	{
		local.bean = CreateObject("component", variables.beanName).init(service = this);

		return local.bean;
	}

}