<cfscript>
  testSuite = createObject( "component", "mxunit.framework.TestSuite" ).TestSuite();
  testSuite.addAll( "dbsugarStructureTest" );
  testSuite.addAll( "dbsugarSelectTest" );
  testSuite.addAll( "dbsugarDataManipulationTest" );
  results = testSuite.run();
  writeOutput( results.getResultsOutput( 'html' ) );
</cfscript>