component extends="mxunit.framework.TestCase" {
  
  public void function setUp() {
    variables.dsn = "cfartgallery";
    variables.db = new dbsugar.dbservice(variables.dsn,false);
  }

  public void function testBasicSelect() {
    var table = "ORDERSTATUS";
    var data = variables.db.select( table );
    var actual = rawQuery("SELECT * FROM #table#");
    assertIsQuery( data, "data wasn't a query!" );
    assertEquals( data.recordCount, actual.recordCount, "Recordcount of manual query was not the same as test of dbservice for the table #table#");
    assertEquals( data, actual, "The manual query wasn't the same as the test query for the table #table#");
  }

  public void function testOrderBy() {
    var table = "ARTISTS";
    var column = "LASTNAME";
    var data = variables.db.select( table=table, orderby=column );
    var actual = rawQuery("SELECT * FROM #table# ORDER BY #column#");
    assertEquals( data, actual, "The manual ordered query wasn't the same as the test query for the table #table#");
  }

  public void function testWhere() {
    var table = "ARTISTS";
    var nullableColumn = "FAX";
    var where1 = {"#nullablecolumn# is"=""};
    var data = variables.db.select( table=table, where=where1);
    var actual = rawQuery("SELECT * FROM #table# WHERE #nullablecolumn# IS NULL");
    assertEquals( data, actual, "NULL filter for #table# wasn't the same as the manual query");
  }


  private function rawQuery(sql){
    return new Query(datasource=variables.dsn).execute(sql=arguments.sql).getResult();
  }



}