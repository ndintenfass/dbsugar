component extends="mxunit.framework.TestCase" {
  
  public void function setUp() {
    variables.dsn = "cfartgallery";
    variables.db = new dbsugar.dbservice(variables.dsn,false);
  }

  public void function testDBStructure() {
    assertEquals( variables.db.getDBType(), "Derby", "DBType was supposed to be 'Derby'" );
  }

  public void function testTableStructure() {
    assertTrue( variables.db.tableExists("ARTISTS"), "Table ARTISTS was supposed to exist" );
    assertTrue( variables.db.columnExists("ORDERS", "ORDERSTATUSID", "Column ORDERSTATUSID was supposed to exist in ORDERS"));
    assertEquals( variables.db.getTablePrimaryKey( "MEDIA" ), "MEDIAID", "The primary key of the table MEDIA was supposed to be MEDIAID" );
  }
}