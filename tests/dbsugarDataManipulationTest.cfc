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
    //cleanArtist();
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


  //show("Delete the new artist","db.deleteRow('artists',newid);");