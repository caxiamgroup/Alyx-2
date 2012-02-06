<cfcomponent hint="This is a hotfix for Coldfusion 9.  Currently there is no way to access cfsetting from script, so I have a dummy object that fixes this issue.">
	<cffunction name="init" hint="This function takes any arguments that you would pass as attributes to the CFSetting tag">
		<cfsetting attributeCollection="#arguments#"/>
	</cffunction>
</cfcomponent>