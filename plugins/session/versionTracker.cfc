component
{
	public function init(required value)
	{
		variables.value = arguments.value;
		variables.version = versionTracker_getCurrentVersion();
	}

	private function versionTracker_getCurrentVersion()
	{
		return application.controller.getSetting(name = 'versionTracker_version', defaultValue = '1');
	}

	private function versionTracker_isCurrentVersion()
	{
		return variables.version == versionTracker_getCurrentVersion();
	}

	private function versionTracker_loadNewVersion()
	{
		writeDump(GetMetadata(variables.value));
		writeDump("hi");
		abort;
	}

	private function versionTracker_subObjectHasFunction(required functionName)
	{
		return StructKeyExists(variables.value, functionName);
	}

	public function onMissingMethod(required missingMethodName, required missingMethodArguments)
	{
		if(!versionTracker_isCurrentVersion())
		{
			versionTracker_loadNewVersion();
		}

		return Evaluate("variables.value.#arguments.missingMethodName#(argumentCollection = arguments.missingMethodArguments)");
	}

}