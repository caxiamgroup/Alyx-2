component
{
	public function init(alyx)
	{
		variables.alyx = arguments.alyx;
		StructAppend(variables, variables.alyx.getPlugin("utils"));
		return this;
	}

	private function getSetting(name)
	{
		return variables.alyx.getSetting(argumentCollection = arguments);
	}

	private function getPlugin(name)
	{
		return variables.alyx.getPlugin(arguments.name);
	}

	private function getView()
	{
		return request.view;
	}

	private function setView(name)
	{
		request.view = arguments.name;
	}

	private function renderJson()
	{
		request.rendering = "json";
	}

	private function renderXML()
	{
		request.rendering = "xml";
	}

	private function setNoLayout()
	{
		setLayout("");
	}

	private function setNoRender()
	{
		setLayout("");
		setView("");
	}

	private function runControllerMethod()
	{
		return variables.alyx.runControllerMethod(argumentCollection = arguments);
	}

	private function redirect(action)
	{
		return variables.alyx.redirect(argumentCollection = arguments);
	}

	private function persist(keys)
	{
		return variables.alyx.persist(argumentCollection = arguments);
	}

	private function logException(exception)
	{
		variables.alyx.logException(argumentCollection = arguments);
	}

	private function getLayout()
	{
		return request.layout;
	}

	private function setLayout(name)
	{
		request.layout = arguments.name;
	}

	private function getService(name)
	{
		return variables.alyx.getService(arguments.name);
	}

	private function getForm(required name)
	{
		return variables.alyx.getPlugin("forms").getForm(arguments.name);
	}


}
