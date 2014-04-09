<cfscript>
  testSuite = createObject( "component", "mxunit.framework.TestSuite" ).TestSuite();
  testSuite.addAll( "dbsugarStructureTest" );
  testSuite.addAll( "dbsugarSelectTest" );
  testSuite.addAll( "dbsugarDataManipulationTest" );
  testSuite.addAll( "dbsugarMySQLTest" );
  results = testSuite.run();
  writeOutput( results.getResultsOutput( 'html' ) );
</cfscript>