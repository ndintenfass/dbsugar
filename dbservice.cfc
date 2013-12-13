<cfcomponent output="false" accessors="true" hint="Deals with all the SQL calls, to keep the clutter out of the dataService">
  <cfproperty name="dsn">
  <cfproperty name="tableMetaData">
  <cfproperty name="databaseType">
  <cfproperty name="dataTypeLookup">
  <cfproperty name="autoPKGen" default="false" type="boolean">
  <!---    
    Please Note:
    
    The methods here generally do not enumerate their arguments specifically.
    
    dbService acts primarily to keep clutter out of other services, and the convention
    is that the names of the arguments will correspond directly to the names of the table columns.

    It does not provide magical SQL abstractions but is rather just intended to save you lines of code for common SQL queries

    Should work with both MySQL and SQLServer.

    We use tag-based syntax for the component to make the SQL queries a lot easier to write within this component.
  --->

  <cfscript>
    function init( required dsn, boolean autoPKGen=true ){
      setDSN( arguments.dsn );
      setAutoPKGen( arguments.autoPKGen );
      refresh();
      return this;
    }

    function recordExists( required table, required value, field=getTablePrimaryKey( arguments.table ) ){
      return selectByValue(arguments.table,arguments.field,arguments.value).recordCount GT 0;
    }

    function selectByValue( required table, required field, required value, columns="*", orderby ){
      var arguments.where = { "#arguments.field#" = arguments.value };
      return select( argumentCollection = arguments );
    }

    function selectRow( required table, required value, field=getTablePrimaryKey( arguments.table ), columns="*" ){
      return selectByValue(argumentCollection=arguments);
    }

    function deleteRow( required table, required value, field=getTablePrimaryKey(arguments.table) ){
      return delete(table=arguments.table,where={"#arguments.field#"=arguments.value});
    }

    function save( required table, generatePK=getAutoPKGen() ){
      local.pkfield = getTablePrimaryKey(arguments.table);
      if(NOT len(trim(local.pkfield)))
        throw("No primary key column is defined in the table #arguments.table#. The abstract SAVE() can only be used on tables with primary keys");
      //if we pass in the primary key field and that record already exists it means we're updating, otherwise inserting
      if(structKeyExists(arguments,local.pkField) and len(trim(arguments[local.pkField])) AND recordExists(arguments.table,arguments[local.pkfield])){
        structDelete(arguments,generatePK);
        return update(argumentCollection=arguments);
      }
      else{
        //need to THIS scope here to avoid collision with the string function "insert"
        return this.insert(argumentCollection=arguments);
      }  
    }

    function makeTableLookup( required table, required key, value=arguments.key, where){
      var args = {  table=arguments.table,
                    columns="#arguments.key#,#arguments.value#"
                  };
      if(structKeyExists( arguments,"where" ))
        args.where = arguments.where;          
      return queryToStruct( selectAll( argumentCollection=args ), arguments.key, arguments.value );
    }

    function queryToStruct( required query, required key, value=arguments.key ){
      var str = {};
      var i = 0;
      for(i = 1; i LTE arguments.query.recordCount; i++){
        str[arguments.query[arguments.key][i]] = arguments.query[arguments.value][i];
      }
      return str;
    }

    function tableExists( required table ){
      return structKeyExists( getTableMetaData(), arguments.table );
    }

    function columnExists( required table, required column ){
      return structKeyExists( getTableMetaData()[arguments.table].columns, arguments.column );
    }

    function dataTypetoCFSQLType( required type ){
      arguments.type = trim(replacenocase(arguments.type," identity",""));
      local.datatypelookup = getdatatypelookup();
      if(NOT structKeyExists(local.datatypelookup,arguments.type)) throw("Unknown data type in translating from CF to SQL #arguments.type#");
      return local.datatypelookup[arguments.type];
    }

    function getTablePrimaryKey( required table ){
      return getTableMetaData()[arguments.table].primaryKey;
    }

    function getTableColumnCount( required table ){
      return getTableMetaData()[arguments.table].columnCount;
    }

    function getColumnCFSQLType( required table, required column ){
      //if this is a list of tables we need to match the right one
      if(find(",",arguments.table)){
        if(NOT find(".",arguments.column)){
          throw("The column #arguments.column# needs to be qualified with a table name when requesting data from more than one table");
        }
        var tablequalifier = listFirst(arguments.column,".");
        if(NOT listFindNoCase(arguments.table,tableQualifier)){
          throw("The column #arguments.column# is qualified with a table name not found in the requested tables");
        }
        arguments.table = tableQualifier;
        arguments.column = listRest(arguments.column,".");
      }
      return getTableMetaData()[trim(arguments.table)].columns[arguments.column].cfsqltype;
    }

    function getColumnMetaData( required table, required column ){
      return duplicate(getTableMetaData()[arguments.table].columns[arguments.column]);
    }

    function makePKValue(){
      return createUUID();
    }

    private function prepareColumnData( required table, generatePK=getAutoPKGen() ){
      if(NOT tableExists(arguments.table))
        throw("Invalid table name #arguments.table# - not found in the current database");
      local.data = {};
      local.pkField = getTablePrimaryKey(arguments.table);
      for(var key in arguments){
        //don't bother adding keys that don't exist or that have null values
        if(key EQ "table" OR key EQ "generatePrimaryKey" OR NOT columnExists(arguments.table,key) OR isNull(arguments[key])) continue;
        //if this is the primary key but the value is empty don't add it, as we assume that means you want the DB to handle the value
        if(key EQ local.pkField AND NOT len(arguments[key]))
          continue;
        local.data[key] = makeColumnDataEntry(arguments.table,key,arguments[key]);
      }
      if(arguments.generatePK AND NOT structKeyExists(local.data,local.pkField))
        local.data[local.pkField] = makeColumnDataEntry(arguments.table,local.pkField,makePKValue());
      return local.data;
    }

    private function makeColumnDataEntry( required table, required field, value=""){
      local.data = getColumnMetaData(arguments.table,arguments.field);
      local.data.value = arguments.value;
      local.data.null = !len( trim( local.data.value ) ) AND local.data.cfsqltype DOES NOT CONTAIN "char" ? true : false;
      return local.data;
    }

    private function processWhereColumns( required where, required table ){
      var processed = {};
      var validOperators = {"=" ="",
                            "<>"="",
                            "!="="",
                            "<" ="",
                            ">" ="",
                            ">="="",
                            "<="="",
                            "in"="",
                            "not in"="",
                            "join"="",
                            "is"="",
                            "is not"=""
                          };
      for(var key in arguments.where){
        local.thisClause = {};
        local.thisClause.column = getToken(key,1);
        local.thisClause.operator = trim(listRest(key,chr(32) & chr(9)));
        local.thisClause.isJoin = local.thisClause.operator EQ "join";
        if(NOT len(local.thisClause.operator) OR local.thisClause.operator EQ "join"){
          local.thisClause.operator = "=";
          local.thisClause.isList = false;
        }
        else{
          local.thisClause.isList = local.thisClause.operator EQ "in" or local.thisClause.operator EQ "not in";
        }
        if(NOT structKeyExists(validOperators,local.thisClause.operator))
          throw("Invalid operator #local.thisClause.operator#"); 
        local.thisClause.value = arguments.where[key];
        local.thisClause.cfSQLType = getColumnCFSQLType(arguments.table,local.thisClause.column);
        local.thisClause.null = (!len(trim(local.thisClause.value)) AND (local.thisClause.cfSQLType DOES NOT CONTAIN "char" OR local.thisClause.operator CONTAINS "is")) ? true : false;
        processed[key] = local.thisClause;
      }
      return processed;
    }

    private function makeSQLToCFDataTypeLookup(){

      switch(getDatabaseType()){
        case "MySQL":
          return {bigint="cf_sql_bigint",
                  binary="cf_sql_binary",
                  bit="cf_sql_bit",
                  char="cf_sql_char",
                  datetime="cf_sql_timestamp",
                  decimal="cf_sql_decimal",
                  double="cf_sql_numeric",
                  float="cf_sql_float",
                  image="cf_sql_longvarbinary",
                  int="cf_sql_integer",
                  money="cf_sql_money",
                  nchar="cf_sql_char",
                  ntext="cf_sql_longvarchar",
                  numeric="cf_sql_decimal",
                  nvarchar="cf_sql_varchar",
                  longtext="cf_sql_longvarchar",
                  real="cf_sql_real",
                  smalldatetime="cf_sql_date",
                  smallint="cf_sql_smallint",
                  smallmoney="cf_sql_decimal",
                  text="cf_sql_longvarchar",
                  timestamp="cf_sql_timestamp",
                  tinyint="cf_sql_tinyint",
                  uniqueidentifier="cf_sql_idstamp",
                  varbinary="cf_sql_varbinary",
                  varchar="cf_sql_varchar"
                };
          case "SQLServer":
          return {int = "cf_sql_integer",
                  bigint = "cf_sql_bigint",
                  smallint = "cf_sql_smallint",
                  tinyint = "cf_sql_tinyint",
                  numeric = "cf_sql_numeric",
                  money = "cf_sql_money4",
                  smallmoney = "cf_sql_money",
                  bit = "cf_sql_bit",
                  decimal = "cf_sql_decimal",
                  float = "cf_sql_float",
                  real = "cf_sql_real",
                  datetime = "cf_sql_timestamp",
                  smalldatetime = "cf_sql_date",
                  char = "cf_sql_char",
                  nchar = "cf_sql_char",
                  varchar = "cf_sql_varchar",
                  nvarchar = "cf_sql_varchar",
                  "nvarchar(max)" = "cf_sql_longvarchar",
                  text = "cf_sql_longvarchar",
                  ntext = "cf_sql_longvarchar",
                  uniqueidentifier = "cf_sql_idstamp",
                  identity = "cf_sql_integer",
                  integer = "cf_sql_integer",
                  memo = "cf_sql_longvarchar",
                  currency = "cf_sql_money",
                  timestamp = "cf_sql_timestamp",
                  boolean = "cf_sql_bit",
                  double = "cf_sql_float"
                };              
        case "Derby":
          return {bigint="cf_sql_bigint",
                  blob="cf_sql_binary",
                  char="cf_sql_char",
                  "CHAR FOR BIT DATA"="cf_sql_char",
                  clob="cf_sql_varbinary",
                  date="cf_sql_date",
                  decimal="cf_sql_decimal",
                  double="cf_sql_numeric",
                  "DOUBLE PRECISION"="cf_sql_numeric",
                  float="cf_sql_float",
                  integer="cf_sql_integer",
                  "LONG VARCHAR"="cf_sql_longvarchar",
                  "LONG VARCHAR FOR BIT DATA"="cf_sql_longvarchar",
                  numeric="cf_sql_decimal",
                  real="cf_sql_real",
                  smallint="cf_sql_smallint",
                  time="cf_sql_time",
                  timestamp="cf_sql_timestamp",
                  varchar="cf_sql_varchar",
                  "VARCHAR FOR BIT DATA"="cf_sql_varchar"
                };        
      }
      throw("Unknown database type while creating a mapping for data types to CF_SQL type: #getDatabaseType()#");
    }
  </cfscript>

  <cffunction name="getDBType" output="false" access="public">
    <cfdbinfo datasource="#getDSN()#" type="version" name="local.info">
    <cfscript>
      if(local.info.database_productname Contains "MySQL")
        return "MySQL";
      if(local.info.driver_name Contains "SQLServer" || local.info.driver_name Contains "Microsoft SQL Server" || local.info.driver_name Contains "MS SQL Server" || local.info.database_productname Contains "Microsoft SQL Server")
        return "SQLServer";
      if(local.info.database_productname Contains "Apache Derby")
        return "Derby";
      throw("Unknown database type is being used: #local.info.database_productname# (#local.info.driver_name#)");
    </cfscript>
  </cffunction>

  <cffunction name="select" access="public" output="false" >
    <cfargument name="table" required="true"  />
    <cfargument name="columns" required="false" default="*"  />
    <cfargument name="orderBy" required="false"  />
    <cfargument name="where" required="false" hint="a struct of column names as keys with filter values, use ' in' after the column name for a multi-filter using IN in the SQL">
    <cfargument name="distinct" required="false" default="false" />
    <cfargument name="limit" required="false">
    <cfset var key = "">
    <cfquery name="local.result" datasource="#getDSN()#">
      SELECT  
              <cfif structKeyExists(arguments,"limit") and getDatabaseType() EQ "SQLServer">
                TOP(#arguments.top#)
              </cfif>
              #arguments.distinct ? "DISTINCT " : ""# #arguments.columns#
      FROM    #arguments.table#
      <cfif structKeyExists( arguments, "where" )>
        <cfset var whereClauses = processWhereColumns( arguments.where, arguments.table )>
        <cfset var thisClause = "">
        WHERE 1=1
        <cfloop collection="#whereClauses#" item="key">
          <cfset thisClause = whereClauses[key]>
          <!--- if we ever need logical "OR" perhaps consider making an optional component that acts as an advanced filter with things like addCritera(column,value,operator,boolean) --->
          AND          
          #thisClause.column# #thisClause.operator# #thisClause.isList ? " (" : ""#
          <cfif NOT thisClause.isJoin>
            <!--- apache derby doesn't like NULL values in CFQUERYPARAM, so we make a special exception --->
            <cfif thisClause.null AND getDBType() EQ "Derby">
              NULL
            <cfelse>
              <cfqueryparam value="#thisClause.value#" null="#thisClause.null#" CFSQLType="#thisClause.CFSQLType#" list="#thisClause.isList#">
            </cfif>
          <cfelse>
            #thisClause.value#    
          </cfif>
          #thisClause.isList ? ")" : ""#
        </cfloop>
      </cfif>
      <cfif structKeyExists(arguments,"orderBy")>
        ORDER BY    #arguments.orderBy#
      </cfif>
      <cfif structKeyExists(arguments,"limit") AND getDatabaseType() EQ "MySQL">
        LIMIT #arguments.limit#
      </cfif>

      
    </cfquery>
    <cfreturn local.result />
  </cffunction>

  <cffunction name="insert" access="public" output="false">
    <cfargument name="table" required="true">
    <cfargument name="generatePK" required="false" default="#getAutoPKGen()#">
    <cfscript>
      var i = 0;
      local.columnData = prepareColumnData(argumentCollection=arguments);   
      local.colCount = structCount(local.columnData); 
      local.pkField = getTablePrimaryKey(arguments.table);
      local.hasPKField = len(local.pkField);
      local.incomingPKValue = local.hasPKField AND structKeyExists(local.columnData,local.pkField) AND len(trim(local.columnData[local.pkField].value));
    </cfscript>
    <cfquery datasource = "#getDSN()#" result="local.queryResult" name="local.insertQuery">
      INSERT INTO #arguments.table#
      (
        #structKeyList(local.columnData)#
      )
      VALUES
      (
        <cfloop collection="#local.columnData#" item="local.thiscol">
          <cfset local.thisColData = local.columnData[local.thiscol]>
          <cfqueryparam value = "#local.thisColData.value#" CFSQLType = "#local.thisColData.cfsqltype#" null="#local.thisColData.null#">
          #++i LT local.colCount ? "," : ""#
        </cfloop>
      )
    </cfquery>
    <!--- if there is a primary key field we either return the one being passed in or the generatedKey if it exists or fall back to an empty string --->
    <cfreturn  local.incomingPKValue ? local.columnData[local.pkField].value : (structKeyExists(local.queryResult,"generatedKey") ? local.queryResult.generatedKey : "")>
  </cffunction>
  
  <cffunction name="update" access="public" output="false">
    <cfargument name="table" required="true">
    <cfargument name="where" required="false" hint="a struct of column names as keys with filter values, use ' in' after the column name for a multi-filter using IN in the SQL">
      <cfscript>
        var i = 0;
        local.pkField = getTablePrimaryKey(arguments.table);
        local.columnData = prepareColumnData(argumentCollection=arguments); 
        //if we have a manual where clause, that overrides the default where clause based on the primary key column
        if(structKeyExists(arguments,"where")){
          local.where = processWhereColumns(arguments.where,arguments.table);
        }
        else{
          if(NOT len(trim(local.pkField)) OR NOT structKeyExists(local.columnData,local.pkField))
            throw("No primary key column was passed for an UPDATE statement on the table #arguments.table#. To use the abstract UPDATE() you must pass the primary key column value.");
          local.pkCol = local.columnData[local.pkField];
          local.where = processWhereColumns({"#local.pkField#"=local.pkCol.value},arguments.table);
        }
        structDelete(local.columnData,local.pkField);
        local.colCount = structCount(local.columnData); 
        var thisClause = "";
      </cfscript>      
      <cfquery datasource = "#getDSN()#">
        UPDATE #arguments.table#
        SET     
          <cfloop collection = "#local.columnData#" item = "local.thiscol">
          <cfset local.thisColData = local.columnData[local.thiscol]>
           #local.thiscol# = <cfqueryparam value="#local.thisColData.value#" cfsqltype="#local.thisColData.cfsqltype#" null="#local.thisColData.null#">
            #++i LT local.colCount ? "," : ""#
          </cfloop>
          WHERE 1=1
          <cfloop collection="#local.where#" item="key">
            <cfset thisClause = local.where[key]>
            <!--- if we ever need logical "OR" perhaps consider making an optional component that acts as an advanced filter with things like addCritera(column,value,operator,boolean) --->
            AND           
            #thisClause.column# #thisClause.operator# #thisClause.isList ? " (" : ""#                                                               
            <cfif NOT thisClause.isJoin>
              <cfqueryparam value="#thisClause.value#" CFSQLType="#thisClause.CFSQLType#" list="#thisClause.isList#">
            <cfelse>
              #thisClause.value#    
            </cfif>
            #thisClause.isList ? ")" : ""#
          </cfloop>
      </cfquery>
      <cfreturn isDefined("local.pkCol") ? local.pkCol.value : "">
  </cffunction>
  

  <cffunction name="delete" access="public" output="false" hint="General purpose delete, with a table name and a struct containing the WHERE clause">
    <cfargument name="table" required="true" hint="Name of the table" />
    <cfargument name="where" required="false" hint="a struct of column names as keys with filter values, use ' in' after the column name for a multi-filter using IN in the SQL">
    <cfquery datasource="#getDSN()#" result="local.queryResult">
      DELETE
      FROM    #arguments.table#
      <cfif structKeyExists(arguments,"where")>
        <cfset var whereClauses = processWhereColumns(arguments.where,arguments.table)>
        <cfset var thisClause = "">
        WHERE 1=1
        <cfloop collection="#whereClauses#" item="key">
          <cfset thisClause = whereClauses[key]>
          <!--- if we ever need logical "OR" perhaps consider making an optional component that acts as an advanced filter with things like addCritera(column,value,operator,boolean) --->
          AND           
          #thisClause.column# #thisClause.operator# #thisClause.isList ? " (" : ""#                                                               
          <cfif NOT thisClause.isJoin>
            <cfqueryparam value="#thisClause.value#" CFSQLType="#thisClause.CFSQLType#" list="#thisClause.isList#">
          <cfelse>
            #thisClause.value#    
          </cfif>
          #thisClause.isList ? ")" : ""#
        </cfloop>
      </cfif>
    </cfquery>
    <cfreturn>
  </cffunction>

  <cffunction name="rawsql" access="public" output="false" hint="USE VERY CAUTIOUSLY">
    <cfargument name="sql" required="true">
    <cftransaction>
    <cfloop list="#trim(arguments.sql)#" delimiters=";" index="local.thischunk">
      <cfif len(trim(local.thisChunk))>
        <cfquery datasource="#getDSN()#">
          #preserveSingleQuotes(local.thischunk)#
        </cfquery>
      </cfif>
    </cfloop>
    </cftransaction>
  </cffunction>
  
  <cffunction name="refresh" access="public" output="false" hint="Refreshes the cached meta data about the tables in this DSN">
    <cfscript>
      var tables = "";
      var tableMetaData = {};
      var thisTable = "";
      setDatabaseType(getDBType());
      setDataTypeLookup(makeSQLToCFDataTypeLookup()); 
    </cfscript>
    <cfdbinfo datasource="#getDSN()#" type="tables" name="tables">
    <cfquery name="tables" dbtype="query">
      SELECT  *
      FROM    tables
      WHERE   table_type <> 'VIEW'
      AND   table_type <> 'SYSTEM TABLE'
    </cfquery>
    <cfloop query = "local.tables">
      <cfdbinfo datasource="#getDSN()#" type="columns" table="#table_name#" name="local.cols">
      <cfscript>
        thisTable = {};
        //get the primary key field (or blank of there is none)
        local.pkTemp = queryToStruct(local.cols,"IS_PRIMARYKEY","COLUMN_NAME");        
        thisTable.primaryKey = !structKeyExists(local.pkTemp,"yes") ? "" : local.pkTemp.yes;
        //get the column data
        local.cols = queryToStruct(local.cols,"COLUMN_NAME","TYPE_NAME");
        thisTable.columns = {};
        for(var col in local.cols){
          thisTable.columns[col] = {cfsqltype=datatypetoCFSQLType(local.cols[col]),isPrimaryKey=col EQ thisTable.primaryKey};
        }
        thisTable.columnCount = structCount(thisTable.columns);
        tableMetaData[table_name] = thisTable;
      </cfscript>
    </cfloop>
    <cfset setTableMetaData(tableMetaData)>
  </cffunction>

</cfcomponent>
