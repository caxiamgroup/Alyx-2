<cfcomponent name="default" implements="irendering">

	<cffunction name="init">
		<cfreturn THIS />
	</cffunction>

	<cffunction name="renderStartWrapper">
		<cfoutput>
			<ul class="pages">
		</cfoutput>
	</cffunction>

	<cffunction name="renderEndWrapper">
		<cfoutput>
			</ul>
		</cfoutput>
	</cffunction>

	<cffunction name="renderFirstPage">
		<cfoutput>
			<ul class="pagination"><li class="prev"><a href="?#ARGUMENTS.parsedUrlparams#">&laquo;</a></li>
		</cfoutput>
	</cffunction>

	<cffunction name="renderPreviousPage">
		<cfoutput>
			<li class="prev"><a href="?#ARGUMENTS.parsedUrlparams#">&lsaquo;</a></li>
		</cfoutput>
	</cffunction>

	<cffunction name="renderNexPage">
		<cfoutput>
			<li class="next"><a href="?#ARGUMENTS.parsedUrlparams#">&rsaquo;</a></li>
		</cfoutput>
	</cffunction>

	<cffunction name="renderLastPage">
		<cfoutput>
			<li class="next"><a href="?#ARGUMENTS.parsedUrlparams#">&raquo;</a></li></ul>
		</cfoutput>
	</cffunction>

	<cffunction name="renderPage">
		<cfoutput>
				<li>#link#</li>
		</cfoutput>
	</cffunction>

	<cffunction name="getSortOrderClass">
		<cfreturn ARGUMENTS.sortOrder />
	</cffunction>

	<cffunction name="renderRecordPerPage" >
		<cfset var local = StructNew() />
		<cfset local.displayCountID = "displaycount" & createUUID() >
		<cfoutput>
			<div class="select-menu" style="display:inline-block; relative; width: 50px; padding: 0px 0px 0px 5px; top: -3px;"><a href="##" class="select-btn"><span></span>#ARGUMENTS.pageSize#</a>
				<ul style="background:white; width: 50px; min-width: 50px; ">
					<cfloop array="#ARGUMENTS.intervalLinks#" index="local.intervalLink">
						<li >#local.intervalLink#</li>
					</cfloop>
				</ul>
			</div>
			<label>per page</label>
			<script type="text/javascript">
				$(document).ready(function() {
					initSelectMenus('a.select-btn')
					$('.select-row').click(function(event) {
						selectRow(this);
						event.stopPropagation();
					});
				});
			</script>
		</cfoutput>
	</cffunction>

</cfcomponent>