// Preserve existing IDs for the supported city selections.
enum TableRoom {
  oldLahore('Lahore', 'lahore'),
  karachiClan('Karachi', 'karachi'),
  thaiBliss('Multan', 'multan'),
  islamabad('Islamabad', 'islamabad'),
  faisalabad('Faisalabad', 'faisalabad'),
  peshawar('Peshawar', 'peshawar'),
  quetta('Quetta', 'quetta'),
  gujranwala('Gujranwala', 'gujranwala'),
  sialkot('Sialkot', 'sialkot'),
  hyderabad('Hyderabad', 'hyderabad');

  const TableRoom(this.cityName, this.artwork);
  final String cityName;
  final String artwork;
}

extension TableRoomDetails on TableRoom {
  String get title => cityName.toUpperCase();
  String get subtitle => switch (this) {
        TableRoom.oldLahore => 'OYE, PATTA CHAK!',
        TableRoom.karachiClan => 'BOSS, CHAAL CHALO!',
        TableRoom.thaiBliss => 'SOHAN MEETHA, CHAAL TEEKHI!',
        TableRoom.islamabad => 'CHILL SCENE, TEZ CHAAL!',
        TableRoom.faisalabad => 'JUGAT BHI, JEET BHI!',
        TableRoom.peshawar => 'CHAI PIYO, CHAAL CHALO!',
        TableRoom.quetta => 'KARAK CHAI, KARAK CHAAL!',
        TableRoom.gujranwala => 'PEHLWAN WALI CHAAL!',
        TableRoom.sialkot => 'CHAAL KA GOAL KAR!',
        TableRoom.hyderabad => 'SAEEN, PATTA CHALO!',
      };
  bool get locked => false;
  String get imageAsset => 'assets/images/cities/${artwork}_table.png';
  String backgroundAsset({required bool portrait}) =>
      'assets/images/cities/${artwork}_${portrait ? "portrait" : "landscape"}.png';
}
