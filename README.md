dbsugar
=======

Syntactic sugar for SQL queries in ColdFusion scripting, simpler and more elegant than the native script-based query API. It also is aware of the structure of your database, so it can use CFQUERYPARAM under the sheets.

Run the demo.cfm page to see some examples.

In short it would look something like this:

```
dsn = "cfartgallery";
db = createObject("component","dbservice").init( dsn );
allArtists = db.select('artists');
artistWithID1 = db.selectRow('artists',1);
artistsInCAandNY = db.select( table='artists', where={'state in' = 'CA,NY'} );
```