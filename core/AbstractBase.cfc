component
{

	public function init(required self)
	{
		if (GetMetaData(arguments.self).name != GetMetaData(this).name)
		{
			local.value = CreateObject("java", "java.util.Arrays").asList(GetMetaData(createObject("java", "coldfusion.runtime.CustomException")).getConstructors());

			for (local.val in local.value)
			{
				writeDump(local.val.toString());
				writeOutput("<br/>");
			}
			writeDump(GetMetadata(createObject("java", "coldfusion.runtime.CustomException")).getPackage());


			try {
				Throw(object = {message="blah"});
			}
			catch(Any error)
			{
				writeDump(error);
				writeDump(GetMetaData(error).getName());
				writeDump(GetMetaData(error));
				abort;
			}
		}
	}

}