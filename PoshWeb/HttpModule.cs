using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;

namespace PoshWeb
{
	public class HttpModule : IHttpModule
	{
		public void Dispose()
		{

		}

		public void Init(HttpApplication context)
		{
			context.BeginRequest += BeginRequest;
		}

		private void BeginRequest(object sender, EventArgs e)
		{
			RunPosh((HttpApplication)sender);
		}

		private void RunPosh(HttpApplication application)
		{
			var success = TryRunPosh(application, application.Request.PhysicalPath) ||
				TryRunPosh(application, application.Request.PhysicalPath+".ps1")
				;
		}

		private bool TryRunPosh(HttpApplication application, string file)
		{
			if (!".ps1".Equals(Path.GetExtension(file), StringComparison.OrdinalIgnoreCase) || !File.Exists(file)) return false;

			RunPosh(application, file);
			return true;

		}

		private void RunPosh(HttpApplication application, string ps1)
		{
			var runspace = RunspaceFactory.CreateRunspace();
			try
			{
				runspace.Open();

				foreach (var key in application.Request.QueryString.AllKeys)
					runspace.SessionStateProxy.SetVariable(key, application.Request.QueryString[key]);

				var pipeline = runspace.CreatePipeline();





				var sb = new StringBuilder();
				//sb.Append("params([string]$___dir___");
				//foreach (var key in application.Request.QueryString.AllKeys)
				//	sb.Append($",${key}");
				//sb.AppendLine(")");
				//sb.AppendLine("cd $___dir___");
				sb.Append(ps1);
				foreach (var key in application.Request.QueryString.AllKeys)
					sb.Append($" -{key} ${key}");

				pipeline.Commands.AddScript(sb.ToString());



				var result = pipeline.Invoke();
				foreach (var table in from r in result
					where r.BaseObject is Hashtable
					let hashtable = r.BaseObject as Hashtable
					where hashtable != null && (hashtable.ContainsKey("Content")|| hashtable.ContainsKey("Status")||hashtable.ContainsKey("ContentType"))
					select hashtable)
				{
					application.Context.Response.ContentType = TryGetValue(table, "ContentType")?? "application/json";
					application.Context.Response.Status = TryGetValue(table, "Status") ?? "200 Ok";
					var content = TryGetValue(table, "Content");
					if (content != null)
						application.Context.Response.Write(content);
					application.CompleteRequest();
					return;
				}

			}
			catch (Exception e)
			{
				application.Context.Response.ContentType = "text/html; charset=UTF-8";
				application.Context.Response.Write("<h1>Error</h1><br><pre>" + e);
				application.Context.Response.Status = "500 Failed";
				application.CompleteRequest();
			}
			finally
			{
				runspace.Close();
			}
		}

		private string TryGetValue(Hashtable table, string key)
		{
			if (table.ContainsKey(key))
				return string.Empty + table[key];
			return null;
		}
	}
}
