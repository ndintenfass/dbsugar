component extends="dbsugarAbstractTest" {

  function testBasicSelect() {
    var table = "ORDERSTATUS";
    var data = variables.db.select( table );
    var actual = rawQuery("SELECT * FROM #table#");
    assertIsQuery( data, "data wasn't a query!" );
    assertEquals( data.recordCount, actual.recordCount, "Recordcount of manual query was not the same as test of dbservice for the table #table#");
    assertEquals( data, actual, "The manual query wasn't the same as the test query for the table #table#");
  }

  function testOrderBy() {
    var table = "ARTISTS";
    var column = "LASTNAME";
    var data = variables.db.select( table=table, orderby=column );
    var actual = rawQuery("SELECT * FROM #table# ORDER BY #column#");
    assertEquals( data, actual, "The manual ordered query wasn't the same as the test query for the table #table#");
  }

  function testWhereNull() {
    var table = "ARTISTS";
    var nullableColumn = "FAX";
    var where1 = {"#nullablecolumn# is"=""};
    var data = variables.db.select( table=table, where=where1);
    var actual = rawQuery("SELECT * FROM #table# WHERE #nullablecolumn# IS NULL");
    assertEquals( data, actual, "NULL filter for #table# wasn't the same as the manual query");
  }

  function testWhereIn(){
    var data = db.select( table="artists", where={"state in" = "CA,NY"} );
    var actual = rawQuery("SELECT * FROM artists WHERE state IN ('CA','NY')");
    assertEquals( data, actual, "MULTI-VALUE 'IN CLAUSE' FAILED");
  }

  function testCount(){
    var data = db.selectCount( "artists" );
    var actual = rawQuery("SELECT COUNT(*) as countvalue FROM artists").countvalue;
    assertEquals( data, actual, "Count of artists was not the same");
  }

  function testCountWhere(){
    var data = db.selectCount( table="artists", where={"state in" = "CA,NY"} );
    var actual = rawQuery("SELECT COUNT(*) as countvalue FROM artists WHERE state IN ('CA','NY')").countvalue;
    assertEquals( data, actual, "Count of artists with a where clause was not the same");
  }

  function testLike(){
    var data = db.select( table="artists", where={"lastname LIKE"="T%"} );
    var actual = rawQuery("SELECT * FROM artists WHERE lastname LIKE 'T%'");
    assertEquals( data, actual, "Simple LIKE comparison failed");
  }

  function testBetween(){
    var data = db.select( table="orders", where={"orderstatusid BETWEEN"="3 AND 5"} );
    var actual = rawQuery("SELECT * FROM orders WHERE orderstatusid BETWEEN 3 AND 5");
    assertEquals( data, actual, "Simple BETWEEN comparison failed");
  }
  function testNotBetween(){
    var data = db.select( table="orders", where={"orderstatusid NOT BETWEEN"="3 AND 5"} );
    var actual = rawQuery("SELECT * FROM orders WHERE orderstatusid NOT BETWEEN 3 AND 5");
    assertEquals( data, actual, "Simple NOT BETWEEN select failed");
  }

  function testSimpleOR(){
    var data = db.select( table="artists", where={state="CA",city="New York"}, whereboolean="OR" );
    var actual = rawQuery("SELECT * FROM artists WHERE state = 'CA' OR city = 'New York'");
    assertEquals( data, actual, "Simple OR operator failed");
  }  

}



