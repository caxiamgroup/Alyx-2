component name="DatasetBean" extends="dataset" output="no"
{

	function getCount()
	{
		return ArrayLen(variables.data);
	}

	function getId(row = variables.currentRow)
	{
		var value = evaluate("variables.data[arguments.row].get#variables.idField#()");
		return value;
	}

	function getLabel(row = variables.currentRow)
	{
		var value = evaluate("variables.data[arguments.row].get#variables.labelField#()");
		return value;
	}

	function getGroupId(row = variables.currentRow)
	{
		var value = evaluate("variables.data[arguments.row].get#variables.groupIdField#()");
		return value;
	}

	function getGroupLabel(row = variables.currentRow)
	{
		var value = evaluate("variables.data[arguments.row].get#variables.groupLabelField#()");
		
		return value;
	}

}