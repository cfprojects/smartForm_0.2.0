<!---
  AUTHOR: Ryan Johnson <rhino.cit.guy@gmail.com>
  DATE: April 26, 2011
  VERSION: 0.2.0
  LICENSE: GPLv3 (see http://www.gnu.org/licenses/gpl.html for more information)
  DESCRIPTION:

    The FORM scope is fairly narrow in what it can hold within it. For starters,
    it can only hold keys directly within the FORM struct. Nested objects and
    collections are not possible using vanilla CF methods.
    
    Take the following as examples.
    
    FORM.foo.bar
    
    You would expect the key 'foo' in the FORM scope to contain a structure with
    the key of 'bar'. Vanilla CF treats it like FORM['foo.bar']. This is not
    nice because we cannot perform manipulation of all keys within FORM.foo
    without complicated ColdFusion code.
    
    FORM.foo[1].bar
    
    This is another interesting one. You would expect the key 'foo' to contain
    an array of structs for the purpose of looping over each element in the
    FORM.foo array. However, vanilla CF treats it as FORM['foo[1].bar']. Again,
    this is highly unusable on the receiving end as I would need to perform some
    complicated logic to separate each individual 'foo' entry for processing.
    
    
    The smartForm function aims to alleviate these woes with the FORM scope by
    transforming the values into the collections and objects that you would
    expect in the examples above.
    
    The function will look for FORM._smart_form = 'yes' to transform the FORM
    scope, otherwise it will leave the FORM scope alone. This is useful because
    you can call this function in Application.cfc in onRequestStart() to
    transform the scope for any form that wishes to make use of this functionality.
--->

<cffunction name="smartForm"
  access="public" returntype="struct" output="No"
  hint="Alias for smart_form()"
>
  <cfargument name="form_struct" required="yes" type="struct">
  <cfreturn smart_form(form_struct)>
</cffunction>
<!---end:smartForm()--->

<cffunction name="smart_form"
  access="public" returntype="struct" output="yes"
  hint="
    This function is meant to be used in the onRequestStart() method or similar
    framework method to transform a plain FORM scope struct into a useful structure
    complete with nested values.
    
    All that is needed is to pass FORM._smart_form = 'yes' to whatever page you
    need the functionality.
  "
>
  <cfargument name="form_scope" required="yes" type="struct">
  <cfscript>
    param ARGUMENTS.form_scope._smart_form = "no";
    var final_output = {};
  </cfscript>
  <cfscript>
    if (ARGUMENTS.form_scope._smart_form EQ "yes") {
      final_output = parse_struct(ARGUMENTS.form_scope);
    } else {
      final_output = ARGUMENTS.form_scope;
    }
    
    // Overwrite any and all values in original scope
    StructAppend(ARGUMENTS.form_scope, final_output, true);
    
    // Return possibly modified struct
    return ARGUMENTS.form_scope;
  </cfscript>
</cffunction>
<!---end:smart_form()--->


<cffunction name="parse_struct"
  access="public" returntype="struct" output="no"
  hint="
    RECURSIVE!
    Messy Struct goes in. Clean struct Comes out.
    This function will dive as deep as it needs to clean up values.
  "
>
  <cfargument name="input" required="yes" type="struct">
  <cfscript>
    var output_struct = {};
    var dirty_struct = {};
    var dirty_array_struct = {};
    
    // Sort key list for consistent functionality
    var key_list = StructKeyList(ARGUMENTS.input);
    var sorted_key_list = ListSort(key_list, 'textnocase');
  </cfscript>
  
  <cfif key_list DOES NOT CONTAIN '.' AND key_list DOES NOT CONTAIN '['>
    <cfset output_struct = ARGUMENTS.input>
  <cfelse>

    <!--- Separate Proper Struct from Problematic Struct --->
    <cfloop list="#sorted_key_list#" index="key">
      <cfscript>
        // This is needed because CF doesn't seem to scope the index properly
        var this_key = key;
        if (this_key NEQ "fieldnames") {
          if (this_key DOES NOT CONTAIN "[") {
            /*
              Must use the quoted variable for dot-notated values
              This will take care of the simple fixes with the purely
              dot-notated keys.
            */
            "output_struct.#this_key#" = ARGUMENTS.input[this_key];
            // Remove old key from input for cleaner result struct
            StructDelete(ARGUMENTS.input, this_key); 
          } else {
            /*
              Add to the dirty_struct for further processing
              These are typically array-notated keys.
            */
            dirty_struct[this_key] = ARGUMENTS.input[this_key];
          }
        }// Skip "FORM.fieldnames"
      </cfscript>
    </cfloop>

    <!--- ========== Generate Cleaner Struct ============================== --->
    <!---
      This is for recursion. We need to clean up the current level of keys so
      we can pass the modified struct value back through the function.
    --->
    <cfloop collection="#dirty_struct#" item="this_key">
      <cfscript>
        // This is needed because CF doesn't seem to scope the index properly
        var dirty_key = this_key;
        
        /*
          If later processes remove keys dynamically from the dirty struct,
          this will ensure that we do not get an exception.
        */
        if (StructKeyExists(dirty_struct, dirty_key)) {
          /* ---------- Determine Metadata about Key/Value ------------------ */
          var meta = {
            original = { key = dirty_key, value = dirty_struct[dirty_key] },
            parent = { key = ListFirst(dirty_key, '.') },
            child = {
              key = ListRest(dirty_key, '.'),
              depth = ListLen(dirty_key, '.'),
              value = dirty_struct[dirty_key]
            }
          };
          if (meta.parent.key CONTAINS "[") {
            meta.parent.key_type = "ARRAY";
            try {
              meta.parent.array_index = ListGetAt(meta.parent.key, 2, '[]');
            } catch (Any e) {
              meta.parent.array_index = 9999;
            }
            meta.parent.key = ListFirst(meta.parent.key, '[]');
          } else {
            if (ListLen(meta.original.key, '.') GT 1) {
              meta.parent.key_type = "struct";
            } else {
              meta.parent.key_type = "simple";
            }
          }
          /* ----------end:Determine Metadata about Key/Value --------------- */
          
          /*
            This section determines the process required for each inferred value
            type as parsed from the key name. Keys with array notation will be
            processed as arrays (structs as structs, etc.)
          */
          switch(meta.parent.key_type) {
            case "array":
              // get all similar keys
              var similar_keys = getSimilarKeys(dirty_struct, ListFirst(meta.original.key, '.'));
              
              // ensure parent key value is an array
              if(NOT StructKeyExists(dirty_array_struct, meta.parent.key)) {
                dirty_array_struct[meta.parent.key] = [];
              }
              
              /*
                The array is meant to contain a struct of values.
                We need to make sure that each element in the array is defined,
                even if it is an empty struct. This is in the event that the
                form may submit non-sequential indeces.
              */
              var array_index = meta.parent.array_index;
              var parent_array = dirty_array_struct[meta.parent.key];
              
              // Combine similar keys into the current "cleaner" value
              var similar_struct = {};
              for(i=1; i LTE ListLen(similar_keys); i=i+1) {
                var similar_key = ListGetAt(similar_keys, i);
                similar_struct[ListRest(similar_key, '.')] = ARGUMENTS.input[similar_key];
                // Ignore other similar keys in problematic struct
                StructDelete(dirty_struct, similar_key); 
                // Remove original key from input
                StructDelete(ARGUMENTS.input, similar_key); 
              }
              
              /*
                Currently, this script will try to add the array items as it runs
                through the keys.
                
                Do not rely on this process to retain array positions as there's
                a possibility that items will be out of place. Especially if there
                are nonsequential or missing indices.
                
                To try and prevent this, code your form to have sequential indices.
              */
              dirty_array_struct[meta.parent.key] = insertIntoArrayAt(parent_array, array_index, similar_struct);
              
              StructAppend(dirty_struct, dirty_array_struct);
            break;
            
            case "struct":
              // group similar keys
              var similar_keys = getSimilarKeys(dirty_struct, ListFirst(meta.original.key, '.'));
              
              // Combine similar keys into the current 'cleaner' value
              var similar_struct = {};
              for(i=1; i LTE ListLen(similar_keys); i=i+1) {
                var similar_key = ListGetAt(similar_keys, i);
                similar_struct[ListRest(similar_key, '.')] = ARGUMENTS.input[similar_key];
                // Ignore other similar keys in problematic struct
                StructDelete(dirty_struct, similar_key); 
                // Remove original key from input
                StructDelete(ARGUMENTS.input, similar_key); 
                
              }
              similar_struct = {
                "#listFirst(meta.original.key, '.')#" = similar_struct
              };
              StructAppend(dirty_struct, similar_struct);
            break;
            
            case "simple":
              /*
                Must use the quoted variable for dot-notated values
                This will take care of the implied nesting.
              */
              "output_struct.#meta.parent.key#" = meta.original.value;
              StructDelete(ARGUMENTS.input, meta.parent_key);
            break;
            
            
            default: /* Do Nothing */ break;
          }//end:switch key type
        }
      </cfscript>
    </cfloop>

    <!--- ========== RECURSION!! ========================================== --->
    <!---
      Now let's go through the cleaner struct and feed it back into
      parse_struct() for recursive functionality.
    --->
    <cfloop list="#StructKeyList(dirty_struct)#" index="dirty_key">
      <cfscript>
        // This is needed because CF doesn't seem to scope the index properly
        var current_key = dirty_key;
        
        var current = dirty_struct[current_key];
        
        if (isStruct(current)) {
          dirty_struct[current_key] = parse_struct(current);
        } else if (isArray(current)) {
          var tmp_array = [];
          for(i=1; i LTE ArrayLen(current); i=i+1) {
            var item = current[i];
            if (isStruct(item)) {
              ArrayAppend(tmp_array, parse_struct(item));
            }
          }//end:current loop
          dirty_struct[current_key] = tmp_array;
        }
        
        StructAppend(output_struct, dirty_struct, true);
      </cfscript>
    </cfloop>
    <!--- ========== end:RECURSION!! ====================================== --->
  </cfif>
  <cfreturn output_struct>
</cffunction>
<!---end:parse_struct()--->


<cffunction name="insertIntoArrayAt"
  access="public" returntype="array" output="Yes"
  hint=""
>
  <cfargument name="target_array" required="yes" type="array">
  <cfargument name="position" required="yes" type="numeric" default="9999">
  <cfargument name="object" required="yes" type="any">
  <cfargument name="clean" required="no" type="boolean" default="true">
  <cfscript>
    if (position GT ArrayLen(target_array)) {
      try {
        target_array[position] = {};
      } catch(Any e) {
        for(i=1; i LT position; i=i+1) {
          ArrayAppend(target_array, {});
        }
      }
    }
    ArrayInsertAt(target_array, position, object);
  </cfscript>
  
  <cfif clean>
    <cfset var output = []>
    <cfloop array="#target_array#" index="i">
      <cfscript>
        if (IsDefined("i")) {
          if (
            NOT (IsStruct(i) AND StructIsEmpty(i)) OR
            (IsArray(i)) OR
            (IsSimpleValue(i))
          ) {
            ArrayAppend(output, i);
          }
        }
      </cfscript>
    </cfloop>
    <cfreturn output>
  <cfelse>
    <cfreturn target_array>
  </cfif>
</cffunction>
<!---end:insertIntoArrayAt()--->


<cffunction name="getSimilarKeys"
  access="public" returntype="string" output="yes"
  hint="Find all keys that belong in the same level as search term."
>
  <cfargument name="structure" required="yes" type="struct">
  <cfargument name="search_term" required="yes" type="string">
  <cfscript>
    var keys = StructKeyList(ARGUMENTS.structure);
    // Escape brackets
    search_term = Replace(search_term, '[', '\[', 'all');
    search_term = Replace(search_term, ']', '\]', 'all');
    var output = "";
  </cfscript>
  <cfoutput>
    <cfloop list="#keys#" index="key">
      <cfif ReFind("^#search_term#.*", key, 1)>
        <cfset local.output = ListAppend(local.output, key)>
      </cfif>
    </cfloop>
  </cfoutput>
  <cfreturn output>
</cffunction>
<!---end:getSimilarKeys()--->
