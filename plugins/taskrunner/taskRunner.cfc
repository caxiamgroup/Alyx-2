<cfcomponent>
<cfscript>

	variables.PROGRESS_LOCK = CreateUuid();

	function init()
	{
		variables.currentThread = CreateObject("java", "java.lang.Thread").currentThread();
		variables.objSystem = CreateObject("java", "java.lang.System");
		variables.config = StructNew();

		return this;
	}

	function run()
	{
		if (! StructKeyExists(url, "set") or ! IsNumeric(url.set))
		{
			url.set = 1;
			StructDelete(session, "_taskRunner");
		}

		if (! StructKeyExists(session, "_taskRunner"))
		{
			session._taskRunner = {};
		}

		local.currentSet = url.set;

		local.tasks = getTasks();

		local.numSets = ArrayLen(local.tasks);

		local.config = getConfig();
		if (StructKeyExists(local.config, "siteName"))
		{
			local.siteName = local.config.siteName;
		}
		else
		{
			local.siteName = cgi.http_host;
		}

		local.lockId = getLockId();

		lock name="TASKRUNNER-#local.lockId#" timeout="5" type="exclusive"
		{
			try
			{
				local.setStartTime = Now();

				display("Start Set #local.currentSet# of #local.numSets#: #local.setStartTime#<br/>");

				if (local.currentSet == 1)
				{
					session._taskRunner.progress = {
						startTime = Now(),
						tasks = {}
					};

					this.log(data = "[" & session.sessionId & "]");
				}

				this.log(data = "START    ====== SET " & local.currentSet & " ======");

				for (local.task in local.tasks[local.currentSet])
				{
					runGC();
					this.log(data = "START    " & local.task);
					runTask(local.task);
					this.log(data = "FINISH   " & local.task);
					runGC(); // Yes, this causes it to run twice between tasks. This is intentional.
				}

				if (local.currentSet == local.numSets)
				{
						session._taskRunner.progress.endTime = Now();
						session._taskRunner.progress.elapsed = getElapsedTime(session._taskRunner.progress.startTime, session._taskRunner.progress.endTime);
				}

				this.log(data = "FINISH   ====== SET " & local.currentSet & " ======");

				local.setEndTime = Now();

				display("Finish Set #local.currentSet# of #local.numSets#: #local.setEndTime#<br/>");
				display("Elapsed time: #getElapsedTime(local.setStartTime, local.setEndTime)#<br/>");

				if (local.currentSet < local.numSets)
				{
					local.nextSet = local.currentSet + 1;
					local.runTime = DateAdd("n", 2, Now());

					schedule(
						action = "update",
						task = "TASKRUNNER_#local.lockId#_#local.nextSet#",
						interval = "once",
						operation = "HTTPRequest",
						startDate = "#DateFormat(local.runTime, "mm/dd/yyyy")#",
						startTime = "#TimeFormat(local.runTime, "hh:mm tt")#",
						url = "http://#cgi.http_host##cgi.script_name#?set=#local.nextSet#&#session.urltoken#"
					);
				}
				else
				{
					local.progressDisplay = getProgressDisplay();

					if (application.controller.isDevEnvironment())
					{
						WriteOutput(local.progressDisplay);
						abort;
					}

					local.mailRecipients = getNotificationEmailRecipients();
					if (Len(local.mailRecipients))
					{
						local.mail = new Mail();
						local.mail.setTo(local.mailRecipients);
						local.mail.setFrom("noreply@caxiamgroup.com");
						local.mail.setSubject("Task Runner Complete - #local.siteName#");
						local.mail.setType("html");
						local.mail.send(body = local.progressDisplay);
					}

					session._taskRunner.progressDisplay = local.progressDisplay;
				}
			}
			catch(any error)
			{
				if (application.controller.isDevEnvironment())
				{
					WriteDump(error);
					abort;
				}
				else
				{
					savecontent variable="local.mailBody"
					{
						WriteDump(error);
						WriteDump(cgi);
					}

					local.mailRecipients = getNotificationEmailRecipients();
					if (Len(local.mailRecipients))
					{
						local.mail = new Mail();
						local.mail.setTo(local.mailRecipients);
						local.mail.setFrom("noreply@caxiamgroup.com");
						local.mail.setSubject("Task Runner Error - #local.siteName#");
						local.mail.setType("html");
						local.mail.send(body = local.mailBody);
					}

					this.log(data = "ERROR - " & Trim(error.message & " " & error.detail));

					savecontent variable="local.details"
					{
						WriteDump(var = error, format = "text");
					}
					this.log(data = details, timestamp = "");

					this.abort();
				}
			}
		}
	}

	function runTask(task)
	{
		session._taskRunner.progress.tasks[arguments.task] = {
			startTime = Now()
		};

		session._taskRunner.progress.currentTask = session._taskRunner.progress.tasks[arguments.task];

		try
		{
			Evaluate("this.#arguments.task#()");
		}
		catch(any error)
		{
			session._taskRunner.progress.tasks[arguments.task].error = error;
			logError(error);
		}

		session._taskRunner.progress.tasks[arguments.task].endTime = Now();
		session._taskRunner.progress.tasks[arguments.task].elapsed = GetElapsedTime(session._taskRunner.progress.tasks[arguments.task].startTime, session._taskRunner.progress.tasks[arguments.task].endTime);
	}

	function logError(error)
	{
		savecontent variable="local.errorDetails"
		{
			WriteDump(var = arguments.error, format = "text");
		}

		this.log(data = "ERROR - " & Trim(arguments.error.message & " " & arguments.error.detail));
		this.log(data = local.errorDetails, timestamp = "");
	}

	function getLockId()
	{
		return Hash(GetBaseTemplatePath());
	}

	function getTasks()
	{
		throw(message = "Override this function");

		// Example:

		var tasks = [
			[
				"import"
				,
				"setMaintenanceMode"
				,
				"backup"
				,
				"loadData"
			],
			[
				"fixCategories"
				,
				"fixProducts"
				,
				"fixSnippets"
				,
				"newProducts"
			],
			[
				"addToSolr"
				,
				"appInit"
				,
				"clearMaintenanceMode"
			]
		];

		return tasks;
	}

	function setConfig()
	{
		variables.config = Duplicate(arguments);
	}

	function getConfig()
	{
		return variables.config;
	}

	function log(data)
	{
		if (! StructKeyExists(arguments, "name"))
		{
			arguments.name = ListFirst(GetFileFromPath(GetBaseTemplatePath()), ".");
		}
		if (! StructKeyExists(arguments, "action"))
		{
			arguments.action = "append";
		}
		if (! StructKeyExists(arguments, "timestamp"))
		{
			arguments.timestamp = Now();
		}
		if (! StructKeyExists(arguments, "addNewLine"))
		{
			arguments.addNewLine = true;
		}

		local.logFile = "";

		if (arguments.action == "write" || ! StructKeyExists(session._taskRunner, "logFiles") || ! StructKeyExists(session._taskRunner.logFiles, arguments.name))
		{
			if (! StructKeyExists(arguments, "logDir"))
			{
				arguments.logDir = getLogsDirectory();
			}
			local.logFile = arguments.logDir & arguments.name & "." & DateFormat(Now(), "yyyymmdd") & TimeFormat(Now(), "hhmmss") & ".log";
			session._taskRunner.logFiles[arguments.name] = local.logFile;
			arguments.action = "write";
		}
		else
		{
			local.logFile = session._taskRunner.logFiles[arguments.name];
		}

		if (arguments.action == "write" || (arguments.addNewLine && Len(arguments.timestamp)))
		{
			arguments.data = arguments.timestamp & arguments.data;
		}

		local.file = FileOpen(local.logFile, arguments.action);

		if (arguments.addNewLine)
		{
			FileWriteLine(local.file, arguments.data);
		}
		else
		{
			FileWrite(local.file, arguments.data);
		}

		FileClose(local.file);
	}

	function getLogsDirectory()
	{
		return ExpandPath("/..") & "/logs/";
	}

	function display(text)
	{
		WriteOutput(arguments.text);
	}

	function runGC(pause = 500)
	{
		variables.objSystem.gc();
		variables.objSystem.runFinalization();
		variables.currentThread.sleep(arguments.pause);
	}

	function getElapsedTime(startTime, endTime = Now())
	{
		local.elapsed = DateDiff("s", arguments.startTime, arguments.endTime);
		local.elapsed_min = Int(local.elapsed / 60);
		local.elapsed_sec = local.elapsed - (local.elapsed_min * 60);

		return local.elapsed_min & " min " & local.elapsed_sec & " sec";
	}

	function getProgress()
	{
		lock name="#variables.PROGRESS_LOCK#" timeout="30" type="readonly"
		{
			local.progress = Duplicate(session._taskRunner.progress);
		}

		return local.progress;
	}

	function updateTaskProgress(progress)
	{
		lock name="#variables.PROGRESS_LOCK#" timeout="30" type="exclusive"
		{
			if (StructKeyExists(arguments, "task"))
			{
				session._taskRunner.progress.tasks[arguments.task].progress = arguments.progress;
			}
			else
			{
				session._taskRunner.progress.currentTask.progress = arguments.progress;
			}
		}
	}

	function clearTaskProgress(progress)
	{
		lock name="#variables.PROGRESS_LOCK#" timeout="30" type="exclusive"
		{
			if (StructKeyExists(arguments, "task"))
			{
				StructDelete(session._taskRunner.progress.tasks[arguments.task], "progress");
			}
			else
			{
				StructDelete(session._taskRunner.progress.currentTask, "progress");
			}
		}
	}

	function getNotificationEmailRecipients()
	{
		return application.controller.getSetting("NOTIFICATION_EMAIL_RECIPIENTS");
	}

</cfscript>

	<cffunction name="schedule" output="no">
		<cfschedule attributeCollection="#arguments#"/>
	</cffunction>

	<cffunction name="getProgressDisplay" output="no">
		<cfargument name="layout" default="yes"/>

		<cfscript>

		local.progress = GetProgress();

		if (! StructKeyExists(local.progress, "endTime"))
		{
			local.progress.elapsed = GetElapsedTime(local.progress.startTime);
		}

		local.tasks = local.progress.tasks;
		StructDelete(local.progress, "tasks");

		for (local.task in local.tasks)
		{
			if (IsStruct(local.tasks[local.task]) && ! StructKeyExists(local.tasks[local.task], "endTime") && StructKeyExists(local.tasks[local.task], "startTime"))
			{
				local.tasks[local.task].elapsed = GetElapsedTime(local.tasks[local.task].startTime);
			}
		}

		</cfscript>

		<cfsavecontent variable="local.output">
			<cfoutput>
			<cfif arguments.layout>
			<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
				"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

			<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
			<cfif not StructKeyExists(local.progress, "endTime")>
				<meta http-equiv="refresh" content="10"/>
			</cfif>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
				<title>Task Runner Monitor</title>
				<style type="text/css">
				body, td { font-family: Arial, Helvetica, sans-serif; font-size: 10px; }
				table { border: 1px solid ##C0C0C0; margin-bottom: 4px; }
				th { background-color: ##DDDDDD; font-size: 10px; }
				</style>
			</head>
			<body>
			<cfelse>
				<style type="text/css">
				.importProgress td { font-family: Arial, Helvetica, sans-serif; font-size: 10px; }
				.importProgress table { border: 1px solid ##C0C0C0; margin-bottom: 4px; }
				.importProgress th { background-color: ##DDDDDD; font-size: 10px; }
				</style>
			</cfif>
			<div class="importProgress">
			#dumpTable(local.progress)#
			<cfloop array="#StructSort(local.tasks, "text", "desc", "startTime")#" index="local.task">
				#dumpTable(local.tasks[local.task], UCase(Replace(local.task, "_", " ", "all")))#
			</cfloop>
			</div>
			<cfif arguments.layout>
			</body>
			</html>
			</cfif>
			</cfoutput>
		</cfsavecontent>

		<cfreturn local.output/>
	</cffunction>

	<cffunction name="dumpTable" output="no">
		<cfargument name="data" required="yes"/>
		<cfargument name="label" default=""/>

		<cfset var output = ""/>
		<cfset var key = ""/>

		<cfsavecontent variable="output">
			<cfoutput>
			<table>
			<cfif Len(arguments.label)>
				<tr>
					<th colspan="3" style="text-align:left">#arguments.label#</th>
				</tr>
			</cfif>
			<cfloop collection="#arguments.data#" item="key">
				<cfif key neq "currentTask">
				<tr>
					<td>#key#</td>
					<td>&nbsp;</td>
					<td>
						<cfif IsDate(arguments.data[key])>
							#TimeFormat(arguments.data[key])#&nbsp;&nbsp;&nbsp;#DateFormat(arguments.data[key], "mm/dd/yyyy")#
						<cfelseif IsStruct(arguments.data[key]) and key eq "error">
							#arguments.data[key].message# #arguments.data[key].detail#
						<cfelseif IsSimpleValue(arguments.data[key])>
							#arguments.data[key]#
						</cfif>
					</td>
				</tr>
				</cfif>
			</cfloop>
			</table>
			</cfoutput>
		</cfsavecontent>

		<cfreturn output/>
	</cffunction>

	<cffunction name="execute" output="true">
		<cfargument name="name" required="true"/>
		<cfargument name="params" required="true"/>
		<cfargument name="timeout" default="300"/>

		<cfexecute name="#arguments.name#" arguments="#arguments.params#" timeout="#arguments.timeout#"/>
	</cffunction>

</cfcomponent>