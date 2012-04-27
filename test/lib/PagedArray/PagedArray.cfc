component extends="alyx.test.lib.JavaClassLoader"
{
	this.fileName = "PagedArray";
	this.name = "00000000-0000-0000-0000000000000000-PAGEDARRAY";
	this.project = "ALYX";
	this.localDirectoryPath = ExpandPath("/alyx/java/lib/");

	public function init()
	{
		writeDump(this);
		abort;
		super.init();
		return PagedArray();
	}

	private function PagedArray()
	{
		return getClassReference().init();
	}

}