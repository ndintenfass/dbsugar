component extends="dbsugarAbstractTest" output="false"{

  function beforeTests(){
    variables.dsn = "mysqldbsugartest";
  }

  function testUnsignedInt() {
    var table = "test";
    var data = variables.db.select( table );
    var actual = rawQuery("SELECT * FROM #table#");
    assertIsQuery( data, "data wasn't a query!" );
    assertEquals( data.recordCount, actual.recordCount, "Recordcount of manual query was not the same as test of dbservice for the table #table#");
    assertEquals( data, actual, "The manual query wasn't the same as the test query for the table #table#");
  }

}