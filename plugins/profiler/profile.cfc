component name="profile" accessors="true"
{
	property name="label";
	property name="startTime";
	property name="endTime";
	property name="startingMemory";

	public function init(
		label,
		startTime = getTickCount(),
		endTime = arguments.startTime,
		required runtime
	)
	{
		VARIABLES.label = arguments.label;
		VARIABLES.startTime = arguments.startTime;
		VARIABLES.endTime = arguments.endTime;
		VARIABLES.runtime = arguments.runtime;
		VARIABLES.startingMemory = getMemory();
		return this;
	}

	public function getMemory()
	{
		local.memory = {
			freeAllocatedMemory = VARIABLES.runtime.freeMemory() / 1024 / 1024,
			allocatedMemory = VARIABLES.runtime.totalMemory() / 1024 / 1024,
			maxMemory = VARIABLES.runtime.maxMemory() / 1024 / 1024
		};

		local.memory.percentFreeAllocated = Round((local.memory.freeAllocatedMemory /local.memory.allocatedMemory) * 100);
		local.memory.percentAllocated = Round((local.memory.allocatedMemory / local.memory.maxMemory ) * 100);
		local.memory.usedMemory = local.memory.allocatedMemory - local.memory.freeAllocatedMemory;

		return local.memory;
	}

	public function getTimeElapsed(outputWritten = true)
	{
		local.elapsed = getEndTime() - getStartTime();
		local.elapsed_total = Int(elapsed / 1000) ;
		local.elapsed_min = Int(elapsed_total / 60) ;
		local.elapsed_sec = elapsed_total - (elapsed_min * 60) ;

		local.timeElapsed = getLabel() & " : " & local.elapsed_min & " min " & local.elapsed_sec & " sec (" & local.elapsed & " ms)";

		if(arguments.outputWritten)
		{
			writeoutput("Output written : " & local.timeElapsed & "<br />");/**/
			return "";
		}
		else
		{
			return local.timeElapsed;
		}
	}

	public function displayMemory()
	{
		writedump(VARIABLES.startingMemory);
		writedump(getMemory());
	}

	public function getEndTime()
	{
		return getTickCount();
	}

	public function compareMemoryVariables(memory = getMemory(), outputWritten = true)
	{
		local.currentMemory = getMemory();
		local.startingMemory = VARIABLES.startingMemory;
		local.comparedMemory = {};

		for(local.key in local.currentMemory)
		{
			local.comparedMemory[local.key  & "- CHANGED"] = local.currentMemory[local.key] - local.startingMemory[local.key];
		}

		if(arguments.outputWritten)
		{
			writeoutput("Output written : " & "<br />");/**/
			writedump(local.comparedMemory);
			return "";
		}
		else
		{
			return local.comparedMemory;
		}

	}
}