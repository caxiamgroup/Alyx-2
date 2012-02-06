component name="profiler"
{
	public function init()
	{
		VARIABLES.debugKey = CreateUUID() & "_debugKey";
	}

	public function startProfiling(label)
	{
		local.profile = addProfile(ArgumentCollection = arguments);
	}

	public function stopProfiling()
	{
		local.profile = getProfile();
		getProfiles().remove(local.profile);
		return local.profile;
	}

	public function addProfile(label)
	{
		local.profiles = getProfiles();
		local.debugInstance = getDebugInstance();
		local.startTime = getTickCount();

		local.currentProfile = new profile(
			label = StructKeyExists(arguments, "label") ? arguments.label : "Profile " & (getCurrentProfileIndex() + 1),
			runtime = local.debugInstance.runtime
		);

		local.profiles.add(local.currentProfile);
		return local.currentProfile;
	}

	public function getTimeElapsed(outputWritten = true, profileIndex = getCurrentProfileIndex())
	{
		if(profileIndex GTE 0 AND profileIndex LTE getCurrentProfileIndex())
		{
			local.profile = getProfile(profileIndex);
			return local.profile.getTimeElapsed(outputWritten);
		}
	}

	public function displayMemory(outputWritten = true, profileIndex = getCurrentProfileIndex())
	{
		if(profileIndex GTE 0 AND profileIndex LTE getCurrentProfileIndex())
		{
			local.profile = getProfile(profileIndex);
			return local.profile.displayMemory(outputWritten);
		}
	}

	public function compareMemoryVariables(outputWritten = true, profileIndex = getCurrentProfileIndex())
	{
		if(profileIndex GTE 0 AND profileIndex LTE getCurrentProfileIndex())
		{
			local.profile = getProfile(profileIndex);
			return local.profile.compareMemoryVariables(outputWritten);
		}
	}

	public function getProfile(profileIndex = getCurrentProfileIndex())
	{
		if(profileIndex GTE 0 AND profileIndex LTE getCurrentProfileIndex())
		{
			local.profile = getProfiles().get(profileIndex - 1);
			local.profile.endTime = getTickCount();
			return local.profile;
		}
	}

	public function getCurrentProfile()
	{
		return getProfile();
	}

	public function getProfiles()
	{
		local.debugInstance = getDebugInstance();

		if(!StructKeyExists(local.debugInstance, "profiles"))
		{
			local.debugInstance.profiles = CreateObject("java", "java.util.ArrayList").init();
			local.debugInstance.runtime = CreateObject("java","java.lang.Runtime").getRuntime();
		}

		return local.debugInstance.profiles;
	}

	private function getCurrentProfileIndex()
	{
		return getProfiles().size();
	}

	private function getDebugInstance()
	{
		if(!StructKeyExists(REQUEST, VARIABLES.debugKey))
		{
			REQUEST[VARIABLES.debugKey] = {};
		}

		return REQUEST[VARIABLES.debugKey];
	}

}