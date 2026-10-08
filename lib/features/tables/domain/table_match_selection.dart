import 'table_room.dart';

enum TableTier {
  silver('ADDA', 'LOW STAKES', '100', '100', 'STARTER'),
  gold('MEHFIL', 'MID STAKES', '500', '700', 'POPULAR'),
  platinum('NAWABI', 'HIGHEST STAKES', '2000', '2500', ''),
  diamond('BAAZI', 'EXCLUSIVE STAKES', '10K', '100', '');

  const TableTier(
      this.title, this.subtitle, this.buyIn, this.reward, this.badge);

  bool get locked => this != TableTier.silver;

  // Artwork follows the displayed tier progression; retain existing tier IDs.
  String get imageAsset => switch (this) {
        TableTier.silver => 'assets/images/tables/lobbies/tier_bronze.png',
        TableTier.gold => 'assets/images/tables/lobbies/tier_silver.png',
        TableTier.platinum => 'assets/images/tables/lobbies/tier_gold.png',
        TableTier.diamond => 'assets/images/tables/lobbies/tier_final.png',
      };

  final String title;
  final String subtitle;
  final String buyIn;
  final String reward;
  final String badge;
}

/// Keeps the table choice intact through player setup and game creation.
class TableMatchSelection {
  const TableMatchSelection({required this.room, required this.tier});

  final TableRoom room;
  final TableTier tier;

  // The current solo API uses beginner and master. Keep the progression here
  // so room/tier balancing never depends on a player's manual guest setting.
  String get difficulty =>
      room == TableRoom.oldLahore && tier == TableTier.silver
          ? 'beginner'
          : 'master';
}

class TableMatchArguments {
  const TableMatchArguments(
      {required this.playerName, required this.selection});

  final String playerName;
  final TableMatchSelection selection;
}
