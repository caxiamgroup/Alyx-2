component
{
	public function init(alyx)
	{
		variables.alyx = arguments.alyx;
		//StructAppend(variables, application.controller.getPlugin("utils"));
		return this;
	}

	/*private function restart()
	{
		setNoRender();
	}

	private function saveSearchParams(key, form)
	{
		application.controller.getPlugin("session").setVar("search-" & arguments.key, arguments.form.serialize());
	}

	private function restoreSearchParams(key)
	{
		arguments.key = "search-" & arguments.key;

		if (StructKeyExists(arguments, "reset") && arguments.reset == true)
		{
			application.controller.getPlugin("session").deleteVar(arguments.key);
		}
		else if (application.controller.getPlugin("session").exists(arguments.key))
		{
			arguments.form.deserialize(application.controller.getPlugin("session").getVar(arguments.key));
			arguments.form.setSubmitted();
		}
	}

	private function getSearchParams(key)
	{
		return application.controller.getPlugin("session").getVar(arguments.key);
	}

	private function getSetting(name)
	{
		return application.controller.getSetting(argumentCollection = arguments);
	}

	private function getPlugin(name)
	{
		return application.controller.getPlugin(arguments.name);
	}

	private function getLayout()
	{
		return request.layout;
	}

	private function setLayout(name)
	{
		request.layout = arguments.name;
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
		return application.controller.runControllerMethod(argumentCollection = arguments);
	}

	private function redirect(action)
	{
		return application.controller.redirect(argumentCollection = arguments);
	}

	private function persist(keys)
	{
		return application.controller.persist(argumentCollection = arguments);
	}

	private function getService(name)
	{
		return application.controller.getService(arguments.name);
	}

	private function logException(exception)
	{
		application.controller.logException(argumentCollection = arguments);
	}*/
}
