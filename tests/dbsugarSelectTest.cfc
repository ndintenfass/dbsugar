component extends="mxunit.framework.TestCase" {
  
  public void function setUp() {
    variables.dsn = "cfartgallery";
    variables.db = new dbsugar.dbservice(variables.dsn,false);
  }

  public void function testBasicSelect() {
    var table = "ORDERSTATUS";
    var data = variables.db.select( table );
    var actual = new Query(datasource=variables.dsn).execute(sql="SELECT * FROM #table#").getResult();
    assertIsQuery( data, "data wasn't a query!" );
    assertEquals( data.recordCount, actual.recordCount, "Recordcount of manual query was not the same as test of dbservice for the table #table#");
    assertEquals( data, actual, "The manual query wasn't the same as the test query for the table #table#");
  }

  public void function testOrderBy() {
    var table = "ARTISTS";
    var column = "LASTNAME";
    var data = variables.db.select( table=table, orderby=column );
    var actual = new Query(datasource=variables.dsn).execute(sql="SELECT * FROM #table# ORDER BY #column#").getResult();
    assertEquals( data, actual, "The manual ordered query wasn't the same as the test query for the table #table#");
  }




}