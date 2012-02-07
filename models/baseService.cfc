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
		local.bean = CreateObject("component", variables.beanName).init(service = this);

		return local.bean;
	}

}