// Preserve the original IDs used by existing table selections.
enum TableRoom {
  oldLahore('Lahore', 'lahore'),
  karachiClan('Karachi', 'karachi'),
  dubaiRise('Rawalpindi', 'pindi'),
  thaiBliss('Multan', 'multan'),
  islamabad('Islamabad', 'pindi'),
  faisalabad('Faisalabad', 'lahore'),
  peshawar('Peshawar', 'pindi'),
  quetta('Quetta', 'pindi'),
  gujranwala('Gujranwala', 'lahore'),
  sialkot('Sialkot', 'lahore'),
  hyderabad('Hyderabad', 'karachi'),
  bahawalpur('Bahawalpur', 'multan'),
  sargodha('Sargodha', 'lahore'),
  sukkur('Sukkur', 'karachi'),
  murree('Murree', 'pindi'),
  abbottabad('Abbottabad', 'pindi'),
  gilgit('Gilgit', 'pindi'),
  skardu('Skardu', 'pindi'),
  gwadar('Gwadar', 'karachi'),
  muzaffarabad('Muzaffarabad', 'pindi');

  const TableRoom(this.cityName, this.artwork);
  final String cityName;
  // Reuse the supplied themed artwork until each city has its own asset.
  final String artwork;
}

extension TableRoomDetails on TableRoom {
  String get title => cityName.toUpperCase();
  String get subtitle => 'CHOOSE YOUR TABLE';
  bool get locked => false;
  String get imageAsset => 'assets/images/tables/lobbies/$artwork.png';
}
