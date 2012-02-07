component name="DatasetArray" extends="dataset" output="no"
{

	function getCount()
	{
		return ArrayLen(variables.data);
	}

	function getId(row = variables.currentRow)
	{
		return variables.data[arguments.row];
	}

	function getLabel(row = variables.currentRow)
	{
		return variables.data[arguments.row];
	}

}