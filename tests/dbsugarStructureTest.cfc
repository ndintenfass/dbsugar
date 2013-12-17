component extends="dbsugarAbstractTest" {

  function testDBType() {
    assertEquals( variables.db.getDBType(), "Derby", "DBType was supposed to be 'Derby'" );
  }

  function testTableExists() {
    assertTrue( variables.db.tableExists("ARTISTS"), "Table ARTISTS was supposed to exist" );
  }

  function testColumnExists() {
    assertTrue( variables.db.columnExists("ORDERS", "ORDERSTATUSID", "Column ORDERSTATUSID was supposed to exist in ORDERS"));
  }

  function testPKColumnDiscovery() {
    assertEquals( variables.db.getTablePrimaryKey( "MEDIA" ), "MEDIAID", "The primary key of the table MEDIA was supposed to be MEDIAID" );
  }
}