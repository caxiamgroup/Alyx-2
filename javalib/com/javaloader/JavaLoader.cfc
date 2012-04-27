component
{
	function init(loadPaths = ArrayNew(1))
	{

		variables.key = Hash(ExpandPath("/") & ArrayToList(arguments.loadPaths));

		if (! StructKeyExists(server, "JavaLoaders") || ! StructKeyExists(server.JavaLoaders, variables.key))
		{
			lock type="exclusive" name="#variables.key#" timeout="10"
			{
				if (! StructKeyExists(server, "JavaLoaders"))
				{
					server.JavaLoaders = {};
				}
				if (! StructKeyExists(server.JavaLoaders, variables.key))
				{
					server.JavaLoaders[variables.key] = CreateObject("component", "javaloader.JavaLoader").init(argumentCollection = arguments);
				}
			}
		}

		return this;
	}

	function create()
	{
		return server.JavaLoaders[variables.key].create(argumentCollection = arguments);
	}
}