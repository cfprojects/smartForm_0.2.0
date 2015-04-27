<cfcomponent>


	<cffunction name="onRequestStart">
		<cfscript>
			// Turn FORM struct into "smart" form struct
			FORM = smart_form(FORM);
      param FORM._smart_form = "no";
		</cfscript>
	</cffunction>


  <cfinclude template='_smart_form.cfm'>
</cfcomponent>