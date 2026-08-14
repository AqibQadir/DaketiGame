enum TableRoom { oldLahore, karachiClan, dubaiRise, thaiBliss }

extension TableRoomDetails on TableRoom {
  String get title => switch (this) {
        TableRoom.oldLahore => 'OLD LAHORE',
        TableRoom.karachiClan => 'KARACHI CLAN',
        TableRoom.dubaiRise => 'DUBAI RISE',
        TableRoom.thaiBliss => 'THAI BLISS',
      };

  String get subtitle => switch (this) {
        TableRoom.oldLahore => 'CLASSIC STREET VIBES',
        TableRoom.karachiClan => 'THE CITY THAT NEVER SLEEPS',
        TableRoom.dubaiRise => 'SKYSCRAPERS, HIGH ROLLS,\nONLY FOR THE BOLD',
        TableRoom.thaiBliss => 'HIGH STAKES, HIGH ROLLERS,\nONLY FOR THE BOLD',
      };

  bool get locked => this == TableRoom.thaiBliss;

  String get imageAsset => switch (this) {
        TableRoom.oldLahore => 'assets/images/tables/lobbies/old_lahore.png',
        TableRoom.karachiClan =>
          'assets/images/tables/lobbies/karachi_clan.png',
        TableRoom.dubaiRise => 'assets/images/tables/lobbies/dubai_rise.png',
        TableRoom.thaiBliss => 'assets/images/tables/lobbies/thai_bliss.png',
      };
}
