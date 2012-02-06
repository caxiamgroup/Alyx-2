component
{
	public function init()
	{
		return this;
	}

	public function safeDollarFormat(value = "", defaultValue = arguments.value)
	{
		if (IsNumeric(arguments.value))
		{
			arguments.defaultValue = DollarFormat(arguments.value);
		}
		return arguments.defaultValue;
	}

	public function safeDecimalFormat(required value, defaultValue = arguments.value)
	{
		if (IsNumeric(arguments.value))
		{
			arguments.defaultValue = NumberFormat(arguments.value, ",0.00");
		}
		return arguments.defaultValue;
	}

	public function safeNumberFormat(required value, defaultValue = arguments.value)
	{
		if (IsNumeric(arguments.value))
		{
			arguments.defaultValue = NumberFormat(arguments.value, ",0");
		}
		return arguments.defaultValue;
	}

	public function safeDateFormat(required value, format = "mm/dd/yyyy", defaultValue = arguments.value)
	{
		if (IsDate(arguments.value))
		{
			arguments.defaultValue = DateFormat(arguments.value, arguments.format);
		}
		return arguments.defaultValue;
	}

	public function extractNumber(required value, defaultValue = arguments.value)
	{
		local.results = arguments.defaultValue;
		local.value = ReReplace(arguments.value, "[^0-9.-]", "", "all");
		if (Len(local.value) && IsNumeric(local.value))
		{
			local.results = local.value;
		}

		return local.results;
	}

	public function extractDecimal(required value, defaultValue = arguments.value)
	{
		local.results = arguments.defaultValue;
		local.value = ReReplace(arguments.value, "[^0-9.-]", "", "all");
		if (Len(local.value) && IsNumeric(local.value))
		{
			local.results = NumberFormat(local.value, "0.00");
		}

		return local.results;
	}

	public function tableFormat(required value)
	{
		arguments.value = Trim(arguments.value);
		if (!Len(arguments.value))
		{
			arguments.value = "&nbsp;";
		}
		return arguments.value;
	}

	public function phoneFormat(required value, mask = "xxx-xxx-xxxx")
	{
		local.newValue = arguments.value;

		local.unformattedValue = ReReplace(arguments.value, "[^A-Za-z0-9]", "", "all");

		if (Len(local.unformattedValue) <= 11 && Len(local.unformattedValue) >= 7)
		{
			arguments.mask = Reverse(arguments.mask);
			local.unformattedValue = Reverse(local.unformattedValue);
			local.maskLength = Len(arguments.mask);
			local.valueLength = Len(local.unformattedValue);
			local.maskPosition = 1;
			local.valuePosition = 1;
			local.newValue = "";

			while (local.maskPosition <= local.maskLength && local.valuePosition <= local.valueLength)
			{
				local.maskCharacter = Mid(arguments.mask, local.maskPosition, 1);
				if (local.maskCharacter == "x")
				{
					local.newValue &= Mid(local.unformattedValue, local.valuePosition, 1);
					local.valuePosition++;
				}
				else
				{
					newValue &= local.maskCharacter;
				}
				local.maskPosition++;
			}

			// Special case for closing grouping symbol
			if (local.maskPosition == local.maskLength)
			{
				local.newValue &= Mid(arguments.mask, local.maskPosition, 1);
			}

			local.newValue = Reverse(local.newValue);
		}

		return Trim(local.newValue);
	}

	public function emailFormat(required value)
	{
		arguments.value = Trim(arguments.value);
		if (Len(arguments.value) && IsValid("email", arguments.value))
		{
			arguments.value = "<a href=""mailto:" & arguments.value & """>" & arguments.value & "</a>";
		}
		return arguments.value;
	}

	public function formatDay(value)
	{
		local.suffix = "th";
		switch (value)
		{
			case 1:
			case 21:
			case 31:
				local.suffix = "st";
				break;
			case 2:
			case 22:
				local.suffix = "nd";
				break;
			case 3:
			case 23:
				local.suffix = "rd";
				break;
		}
		return arguments.value & local.suffix;
	}

	public function addressFormat(
		addressLine1 = "",
		addressLine2 = "",
		city = "",
		state = "",
		zipCode = ""
	)
	{
		local.address = "";

		if (Len(arguments.addressLine1))
		{
			if (Len(local.address))
			{
				local.address &= "<br />";
			}
			local.address &= arguments.addressLine1;
		}

		if (Len(arguments.addressLine2))
		{
			if (Len(local.address))
			{
				local.address &= "<br />";
			}
			local.address &= arguments.addressLine2;
		}

		if (Len(arguments.city) || Len(arguments.state) || Len(arguments.zipCode))
		{
			if (Len(local.address))
			{
				local.address &= "<br />";
			}

			if (Len(arguments.city))
			{
				local.address &= arguments.city;

				if (Len(arguments.state))
				{
					local.address &= ", ";
				}
			}

			if (Len(arguments.state))
			{
				local.address &= arguments.state;
			}

			if (Len(arguments.zipCode))
			{
				if (Len(arguments.city) or Len(arguments.state))
				{
					local.address &= "&nbsp;&nbsp;";
				}

				local.address &= arguments.zipCode;
			}
		}

		return local.address;
	}

	public function getForm(required name)
	{
		return application.controller.getPlugin("forms").getForm(arguments.name);
	}

	public function getProfiler()
	{
		return application.controller.getProfiler();
	}

	public function getSnippet(required snippetId)
	{
		return application.controller.getPlugin("snippets").getSnippet(argumentCollection = arguments);
	}

	public function queryToArray(required data, startRow = "", endRow = "")
	{
		var local = {};

		local.converted = [];
		local.numRows = arguments.data.recordCount;

		if (local.numRows > 0)
		{
			local.columns = ListToArray(arguments.data.columnList);

			if (not IsNumeric(arguments.startRow))
			{
				arguments.startRow = 1;
			}
			if (arguments.startRow < 1)
			{
				arguments.startRow = 1;
			}
			if (arguments.startRow > local.numRows)
			{
				arguments.startRow = local.numRows;
			}

			if (not IsNumeric(arguments.endRow))
			{
				arguments.endRow = local.numRows;
			}
			if (arguments.endRow < 1)
			{
				arguments.endRow = 1;
			}
			if (arguments.endRow > local.numRows)
			{
				arguments.endRow = local.numRows;
			}

			for (local.rowIndex = arguments.startRow; local.rowIndex <= arguments.endRow; ++local.rowIndex)
			{
				local.row = {};

				for (local.column in local.columns)
				{
					local.row[local.column] = arguments.data[local.column][local.rowIndex];
				}

				ArrayAppend(local.converted, local.row);
			}
		}

		return local.converted;
	}

	public function queryToStruct(required data, rowIndex = 1)
	{
		var local = {};

		local.columns = ListToArray(arguments.data.columnList);
		local.row = {};

		if (arguments.data.recordCount >= arguments.rowIndex)
		{
			for (local.column in local.columns)
			{
				local.row[local.column] = arguments.data[local.column][arguments.rowIndex];
			}
		}
		else
		{
			for (local.column in local.columns)
			{
				local.row[local.column] = "";
			}
		}

		return local.row;
	}

 	public function capitalize(required string)
	{
		return UCase(Left(arguments.string, 1)) & Mid(arguments.string, 2, Len(arguments.string));
	}

}