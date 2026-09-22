import 'table_room.dart';

enum TableTier {
  silver('SILVER', 'LOW STAKES', '100', '100', 'STARTER'),
  gold('GOLD', 'MID STAKES', '500', '700', 'POPULAR'),
  platinum('PLATINUM', 'HIGHEST STAKES', '2000', '2500', 'PREMIUM'),
  diamond('DIAMOND', 'EXCLUSIVE STAKES', '10K', '10K', 'EXCLUSIVE');

  const TableTier(
      this.title, this.subtitle, this.buyIn, this.reward, this.badge);

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
