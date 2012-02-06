component
{

	public function init(required alyx)
	{
		variables.alyx = arguments.alyx;
		variables.alyx.setPropertyDefaultValues(object = this);
		return this;
	}

	public function onMissingMethod(required missingMethodName, required missingMethodArguments)
	{
		return Evaluate("variables.alyx.#missingMethodName#(ArgumentCollection = missingMethodArguments)");
	}

}