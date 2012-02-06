<cfcomponent extends="workflow_2010.alyx2.core.framework">
<cfscript>

	public function getEnvironment()
	{

		local.environment = super.getEnvironment();

		if (cgi.http_host contains ".ds." && cgi.http_host contains ".caxiamgroup.net")
		{
			local.environment = "ds";
		}

		return local.environment;
	}

	public function getErrorEmailRecipients()
	{
		return "errors@caxiamgroup.com";
	}

	private function getDevUrl()
	{
		return "caxiamgroup.net";
	}

	/**
	  * This should be overridden.
	  * Put all application.controller.initPlugin functions in here.
	  * This allows for your init plugins to be done at one specified place.
	  **/
	private function initPlugins()
	{
		initPlugin(name = "snippets");
		initPlugin(name = "forms");
		initPlugin(name = "session");
		initPlugin(name = "utils");
		initPlugin(name = "profiler");
		initPlugin(name = "paginations");
	}

</cfscript>
</cfcomponent>