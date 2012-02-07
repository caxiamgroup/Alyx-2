component output="no" extends="text"
{

	private function formatValue(required value)
	{
		arguments.value = ReReplace(arguments.value, "[^0-9.-]", "", "all");
		if (IsNumeric(arguments.value))
		{
			arguments.value = NumberFormat(arguments.value, ",0");
		}
		return arguments.value;
	}

}