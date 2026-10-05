enum TableRoom { oldLahore, karachiClan, dubaiRise, thaiBliss }

extension TableRoomDetails on TableRoom {
  String get title => switch (this) {
        TableRoom.oldLahore => 'LAHORI\nBAAZI',
        TableRoom.karachiClan => 'KARACHI\nSCENZ',
        TableRoom.dubaiRise => 'PINDI DA\nADDA',
        TableRoom.thaiBliss => 'MULTANI\nMEHFIL',
      };

  String get subtitle => switch (this) {
        TableRoom.oldLahore => 'LOW STAKES',
        TableRoom.karachiClan => 'MID STAKES',
        TableRoom.dubaiRise => 'HIGHEST STAKES',
        TableRoom.thaiBliss => 'EXCLUSIVE STAKES',
      };

  bool get locked => this == TableRoom.thaiBliss;

  String get imageAsset => switch (this) {
        TableRoom.oldLahore => 'assets/images/tables/lobbies/old_lahore.png',
        TableRoom.karachiClan => 'assets/images/karachi_rain_street.png',
        TableRoom.dubaiRise => 'assets/images/tables/lobbies/dubai_rise.png',
        TableRoom.thaiBliss => 'assets/images/tables/lobbies/thai_bliss.png',
      };
}
