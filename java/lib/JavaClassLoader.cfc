component output="false"
{
/*
 *   CREATED BY ZACH STEVENSON ON 9/15/2011
 *
 *   This Class was designed to load raw java with the javaloader.
 *   You can use this in two possible ways:
 *   #1: Pass the localDirectoryPath in the component.  This will Load a Java File with the name specified in local.fileName into memory.
 *   #2: You can pass the first fileName, name, and project and assign a function getJava() to return source code.  This saves it into memory.
 *
 *
 */

	this.fileName = ""; //THIS NEEDS TO BE DEFINED IN SUBCLASS
	this.name = ""; //THIS NEEDS TO BE DEFINED IN SUBCLASS
	this.project = ""; //THIS NEEDS TO BE DEFINED IN SUBCLASS
	this.localDirectoryPath = ""; //THIS CAN OPTIONALLY BE DEFINED TO LOAD A LOCAL JAVA FILE INSTEAD OF STORING IT INTO MEMORY


	public function init()
	{
		checkServer();
		checkClass();
		return this;
	}

	package function checkServer()
	{
		if(!StructKeyExists(SERVER, this.project))
		{
			SERVER[this.project] = {};
		}
	}

	package function checkClass()
	{
		if(!StructKeyExists(SERVER[this.project], this.name))
		{
			lock name="#this.name#-#this.project#" timeout="0" type="exclusive"
			{
				if(!StructKeyExists(SERVER[this.project], this.name))
				{
					if(IsLocalDirectoryFileAvailable())
					{
						checkLocalDirectoryFile();
						local.sourcePaths = [this.localDirectoryPath];
					}
					else
					{
						local.source = getJava();
						checkMemoryDirectory();
						writeFileToMemory(local.source);
						local.sourcePaths = [getMemoryDirectory()];
					}
					local.loader = getJavaLoader(sourceDirectories = local.sourcePaths);
					SERVER[this.project][this.name] = local.loader.create(this.fileName);
				}
			}
		}
	}

	package function getJavaLoaderClass()
	{
		return createObject("component", "alyx.com.javaloader.javaloader.JavaLoader");
	}

	package function getJavaLoader()
	{
		return getJavaLoaderClass().init(ArgumentCollection = Arguments);
	}

	package function checkMemoryDirectory()
	{
		local.memoryDirectory = getMemoryDirectory();
		if(!DirectoryExists(local.memoryDirectory))
		{
			DirectoryCreate(local.memoryDirectory);
		}
	}

	package function checkLocalDirectoryFile()
	{
		local.filePath = this.localDirectoryPath&this.fileName&".java";
		if(!FileExists(local.filePath))
		{
			Throw("The Java file you are trying to use does not exist!");
		}
	}

	package function getMemoryDirectory()
	{
		return "ram://#this.project#/#this.name#/";
	}

	package function getMemoryFilePath()
	{
		return getMemoryDirectory() & this.fileName &".java";
	}

	package function writeFileToMemory(file)
	{
		FileWrite(getMemoryFilePath(), arguments.file);
	}

	//this needs to be overridden in the subclass
	package function getJava()
	{
		return "";
	}

	package function getClassReference()
	{
		return SERVER[this.project][this.name];
	}

	package function isLocalDirectoryFileAvailable()
	{
		return Len(this.localDirectoryPath);
	}


}