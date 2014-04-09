/**
* @mxunit:decorators mxunit.framework.decorators.AlphabeticallyOrderedTestsDecorator
*/
component extends="mxunit.framework.TestCase" output="false" {
  
  function beforeTests(){
    variables.dsn = "cfartgallery";
  }

  function setUp() {
    variables.db = new dbsugar.dbservice( variables.dsn );
  }

  private function rawQuery(sql){
    return new Query(datasource=variables.dsn).execute(sql=arguments.sql).getResult();
  }

}
