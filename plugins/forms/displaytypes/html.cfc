component output="no" extends="_common"
{

	function render(
		required field,
		required form,
		extra     = "",
		rows      = 3,
		cols      = 25,
		toolbarSet = "",
		width = "",
		height = ""
	)
	{
		var local = {};

		local.fieldName = arguments.form.getFieldName(arguments.field.name);

		if (Len(Trim(arguments.extra)))
		{
			arguments.extra = " " & Trim(arguments.extra);
		}

		local.textArea = '<textarea rel="#arguments.toolbarSet#" rows="#arguments.rows#" cols="#arguments.cols#" name="#local.fieldName#" id="#local.fieldName#"#arguments.extra#>#arguments.form.getFieldValue(arguments.field.name)#</textarea>';

		/*this is for now this needs to be changed*/
		arguments.fieldName = local.fieldName;
		return local.textArea & getCKSetttings(ArgumentCollection = arguments);
	}

	public function getCKSetttings()
	{
		savecontent variable="local.ckSettings"
		{
			writeOutput("$(""###arguments.fieldName#"").ckeditor({
				customConfig : '/media/js/ckeditor.config.js',
				toolbar      : 'CgBoMin',
				skin		   : 'cgbo',
				height       : '#arguments.height#px',
				width       : '#arguments.width#px',
				dialog_backgroundCoverColor : 'rgb(0, 0, 0)'
			});");
		}
		return local.ckSettings;
	}
}