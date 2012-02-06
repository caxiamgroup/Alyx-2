<cfcomponent name="default" implements="irendering">

	<cffunction name="init">
		<cfreturn THIS />
	</cffunction>

	<cffunction name="renderStartWrapper">
		<cfoutput>
			<div class="pages">
		</cfoutput>
	</cffunction>

	<cffunction name="renderEndWrapper">
		<cfoutput>
			</div>
		</cfoutput>
	</cffunction>

	<cffunction name="renderFirstPage">
		<cfoutput>
			<a class="first" title="First" href="?#ARGUMENTS.parsedUrlparams#">&nbsp;</a>
		</cfoutput>
	</cffunction>

	<cffunction name="renderPreviousPage">
		<cfoutput>
			<a class="previous" title="Previous" href="?#ARGUMENTS.parsedUrlparams#">&nbsp;</a>
		</cfoutput>
	</cffunction>

	<cffunction name="renderNexPage">
		<cfoutput>
			<a class="next" title="next" href="?#ARGUMENTS.parsedUrlparams#">&nbsp;</a>
		</cfoutput>
	</cffunction>

	<cffunction name="renderLastPage">
		<cfoutput>
			<a class="last" title="Last" href="?#ARGUMENTS.parsedUrlparams#">&nbsp;</a>
		</cfoutput>
	</cffunction>

	<cffunction name="renderPage">
		<cfoutput>
				#link#
		</cfoutput>
	</cffunction>

	<cffunction name="renderRecordPerPage">
	<cfset var local = StructNew() />
	<cfset local.displayCountID = "displaycount" & createUUID() >
	<cfoutput>
		<div class="select-menu" style="float:left; width: 50px; padding: 0px 0px 0px 5px; position:relative; top: 2px;"><a href="##" class="select-btn"><span></span>#arguments.pageSize#</a>
			<ul style="background:white; width: 50px; min-width: 50px;">
				<cfloop array="#ARGUMENTS.intervalLinks#" index="local.intervalLink">
				<li>#local.intervalLink#</li>
				</cfloop>
			</ul>
		</div>
		<label>per page</label>
	</cfoutput>
	</cffunction>



	<cffunction name="getSortOrderClass">
		<cfreturn ARGUMENTS.sortOrder />
	</cffunction>

</cfcomponent>