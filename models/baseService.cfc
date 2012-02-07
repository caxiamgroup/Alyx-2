component name="baseService" output="no" hint="Abstract base class for model services"
{
	public function init(required alyx)
	{
		variables.alyx = arguments.alyx;
		
		variables.NONEXISTANT_FUNCTION_ON_SERVICE_ERROR = variables.alyx.createCustomException(
			TYPE = "CONTROLLER.COMMON.NONEXISTANT_FUNCTION_ON_SERVICE_ERROR",
			MESSAGE = "The function you are trying to call on the service does not exist"
		);
		return this;
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
		local.serviceName = getMetadata(this).name;
		local.beanName = Left(local.serviceName, (Len(local.serviceName)-7));
		local.bean = CreateObject("component", local.beanName).init(service = this);

		return local.bean;
	}

}