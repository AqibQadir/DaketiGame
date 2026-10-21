import '../../domain/models/daketi_game.dart';

class MatchPlayerIdentity {
  const MatchPlayerIdentity(this.name, this.avatarAsset);

  final String name;
  final String avatarAsset;
}

const _botRoster = <MatchPlayerIdentity>[
  MatchPlayerIdentity('Ahad', 'assets/images/players/ai/ahad.jpg'),
  MatchPlayerIdentity('Aiza', 'assets/images/players/ai/aiza.jpg'),
  MatchPlayerIdentity('Alishba', 'assets/images/players/ai/alishba.jpg'),
  MatchPlayerIdentity('Anaya', 'assets/images/players/ai/anaya.jpg'),
  MatchPlayerIdentity('Areeba', 'assets/images/players/ai/areeba.jpg'),
  MatchPlayerIdentity('Arham', 'assets/images/players/ai/arham.jpg'),
  MatchPlayerIdentity('Ayan', 'assets/images/players/ai/ayan.jpg'),
  MatchPlayerIdentity('Ayesha', 'assets/images/players/ai/ayesha.jpg'),
  MatchPlayerIdentity('Daniyal', 'assets/images/players/ai/daniyal.jpg'),
  MatchPlayerIdentity('Dua', 'assets/images/players/ai/dua.jpg'),
  MatchPlayerIdentity('Eshal', 'assets/images/players/ai/eshal.jpg'),
  MatchPlayerIdentity('Hamza', 'assets/images/players/ai/hamza.jpg'),
  MatchPlayerIdentity('Hania', 'assets/images/players/ai/hania.jpg'),
  MatchPlayerIdentity('Huzaifa', 'assets/images/players/ai/huzaifa.jpg'),
  MatchPlayerIdentity('Ibrahim', 'assets/images/players/ai/ibrahim.jpg'),
  MatchPlayerIdentity('Inaya', 'assets/images/players/ai/inaya.jpg'),
  MatchPlayerIdentity('Iqra', 'assets/images/players/ai/iqra.jpg'),
  MatchPlayerIdentity('Kinza', 'assets/images/players/ai/kinza.jpg'),
  MatchPlayerIdentity('Laiba', 'assets/images/players/ai/laiba.jpg'),
  MatchPlayerIdentity('Mahnoor', 'assets/images/players/ai/mahnoor.jpg'),
  MatchPlayerIdentity('Meher', 'assets/images/players/ai/meher.jpg'),
  MatchPlayerIdentity('Mikaal', 'assets/images/players/ai/mikaal.jpg'),
  MatchPlayerIdentity('Rayyan', 'assets/images/players/ai/rayyan.jpg'),
  MatchPlayerIdentity('Saad', 'assets/images/players/ai/saad.jpg'),
  MatchPlayerIdentity('Shahmeer', 'assets/images/players/ai/shahmeer.jpg'),
  MatchPlayerIdentity('Shayan', 'assets/images/players/ai/shayan.jpg'),
  MatchPlayerIdentity('Taha', 'assets/images/players/ai/taha.jpg'),
  MatchPlayerIdentity('Zain', 'assets/images/players/ai/zain.jpg'),
  MatchPlayerIdentity('Zayan', 'assets/images/players/ai/zayan.jpg'),
  MatchPlayerIdentity('Zoya', 'assets/images/players/ai/zoya.jpg'),
];

int _stableIdentitySeed(String value) {
  var hash = 17;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 37 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

/// The same seat assignment is used by the board and results, before ranking.
Map<String, MatchPlayerIdentity> matchPlayerIdentities(
    DaketiGame game, String? localPlayerId, String matchId) {
  final localIndex = game.players.indexWhere((p) => p.id == localPlayerId);
  final opponents = localIndex < 0
      ? game.players.where((p) => p.id != localPlayerId).toList()
      : List.generate(game.players.length - 1,
          (i) => game.players[(localIndex + i + 1) % game.players.length]);
  final seats = [
    if (opponents.length == 1) opponents[0],
    if (opponents.length >= 2) opponents[1],
    if (opponents.length >= 2) opponents[0],
    if (opponents.length >= 3) opponents[2],
  ];
  final seed = _stableIdentitySeed(matchId);
  final step = 1 + (seed ~/ 5) % 4;
  return {
    for (final entry in seats.indexed)
      if (entry.$2.isAi)
        entry.$2.id: _botRoster[(seed + entry.$1 * step) % _botRoster.length],
  };
}
