/**
* @mxunit:decorators mxunit.framework.decorators.AlphabeticallyOrderedTestsDecorator
*/
component extends="mxunit.framework.TestCase" output="false" {
  
  function setUp() {
    variables.dsn = "cfartgallery";
    variables.db = new dbsugar.dbservice(variables.dsn,false);
  }

  private function rawQuery(sql){
    return new Query(datasource=variables.dsn).execute(sql=arguments.sql).getResult();
  }

}
