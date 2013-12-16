<cfscript>
  dsn = "cfartgallery";
  db = createObject("component","dbservice").init( dsn );
  i = 0;
  //writeDump(db.select( table='artists', where={'FAX is'=''} ));
  show("Get all the artists","db.select('artists');");
  show("Artists in California and New York","db.select( table='artists', where={'state in' = 'CA,NY'} );");
  show("Filter artists where FAX is NULL","db.select( table='artists', where={'FAX is'=''} );");
  show("Insert a new artist","newid = db.insert(table='artists',firstName='Jizanthapus',lastName='Szekely');");
  show("Get the new artist","db.selectRow('artists',newid);");
  show("Delete the new artist","db.deleteRow('artists',newid);");


</cfscript>



<cfscript>
  //this is not material to the demo -- just a convenient way to spit out code to the screen and execute it without typing it twice 
  function show(title,code){
    writeOutput("<h2>" & arguments.title & "</h2>");
    writeOutput("<h3>" & htmlCodeFormat(code) & "<h3>");
    fileWrite(expandPath("temp#++i#.cfm"),"<cfscript> function tempcode#i#(){var r = " & code & " if(isDefined('r')) return r;} </cfscript>");
    include "temp#i#.cfm";
    writeDump(evaluate("tempCode#i#()"));
    fileDelete(expandPath("temp#i#.cfm"));
    writeOutput("<hr>");
  }
</cfscript>