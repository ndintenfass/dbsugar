component extends="dbsugarAbstractTest" {
  function testInsert() {
    cleanArtist();
    var newid = db.insert(table='artists',firstName='#getArtist().fname#',lastName='#getArtist().lname#');
    var artist = db.selectRow("artists", newid);
    assertTrue(artistExists());
    assertTrue(artist.recordCount EQ 1);
    assertEquals(artist.firstName,getArtist().fname);
    assertEquals(artist.lastName,getArtist().lname);
    cleanArtist();
  }

  function testDelete() {
    cleanArtist();
    var newid = db.insert(table='artists',firstName='#getArtist().fname#',lastName='#getArtist().lname#');
    var artist = db.selectRow("artists", newid);
    assertTrue(artistExists(), "The artists inserted to test delete didn't work");
    db.deleteRow("artists",newid);
    assertFalse(artistExists(), "Failed to delete the inserted artist");
    cleanArtist();
  }

  function testUpdate() {
    var artists = rawQuery("SELECT * FROM artists");
    var originalEmail = artists.email[1];
    var newemail = "newemail@mailinator.com";
    var toUpdate = {
      table = "artists",
      artistid = artists.artistid[1],
      email = newemail
    };
    db.update(argumentCollection=toUpdate);
    var newArtist = rawQuery("SELECT email from artists where artistid = #artists.artistid[1]#");
    assertEquals(newArtist.email,newEmail);
    //clean up
    rawQuery("UPDATE artists SET email = '#originalEmail#' WHERE artistid = #artists.artistid[1]#");
  }


  private function getArtist(){
    return { fname = "Jizanthapus", lname = "Szekely" };
  }

  private function cleanArtist(){
    rawQuery("delete from artists where firstName = '#getArtist().fname#' AND lastName = '#getArtist().lname#'");
  }

  private function artistExists(){
    return rawQuery("select COUNT(*) as theCount from artists where firstName = '#getArtist().fname#' AND lastName = '#getArtist().lname#'").theCount GT 0;
  }
}
