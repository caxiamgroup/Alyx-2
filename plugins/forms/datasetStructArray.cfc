component name="DatasetStructArray" extends="dataset" output="no"
{

	function getCount()
	{
		return ArrayLen(variables.data);
	}

	function getId(row = variables.currentRow)
	{
		return variables.data[arguments.row][variables.idField];
	}

	function getLabel(row = variables.currentRow)
	{
		return variables.data[arguments.row][variables.labelField];
	}

}