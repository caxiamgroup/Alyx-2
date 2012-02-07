component output="no"
{

	function init(required alyx)
	{
		variables.alyx = arguments.alyx;
		/*
			Having this local reference to the error messages makes a significant
			improvement in the amount of time it takes to render the client side
			validation scripts, due to the removal of the 'getPlugin("snippets")'
			call.
		*/
		variables.errorMessages = arguments.alyx.getPlugin("snippets").getSnippets("errormessages");

		return this;
	}

	function validate(required field, required value)
	{
		validateRequired(argumentCollection = arguments);
		doCustomValidations(argumentCollection = arguments);
	}

	function validateRequired(required field, required value)
	{
		var local = {};

		if (StructKeyExists(arguments.field, "required") && arguments.field.required == true)
		{
			if (! Len(arguments.value))
			{
				local.errorMsg = getErrorMessage("required", arguments.field);
				ArrayAppend(arguments.field.errors, local.errorMsg);
			}
		}
	}

	function getErrorMessage(required messageId, required field)
	{
		var local = {};

		if (StructKeyExists(arguments.field, "errorMsg" & arguments.messageId))
		{
			local.errorMsg = arguments.field["errorMsg" & arguments.messageId];
		}
		else
		{
			local.errorMsg = variables.errorMessages[arguments.messageId];
		}
		local.errorMsg = Replace(local.errorMsg, "%%fieldname%%", arguments.field.label);

		return local.errorMsg;
	}

	/* -------------------- Client Side Validation -------------------- */

	function getClientSideValidationScript(required field, required context)
	{
		clientValidateRequired(argumentCollection = arguments);
		clientDoCustomValidations(argumentCollection = arguments);
	}

	function clientValidateRequired(required field, required context)
	{
		var local = {};

		if (StructKeyExists(arguments.field, "required") && arguments.field.required == true)
		{
			local.errorMsg = getErrorMessage("required", arguments.field);
			arguments.context.output.append("validateRequired(this,'" & arguments.field.name & "','" & JSStringFormat(HTMLEditFormat(local.errorMsg)) & "');");
		}
	}

}