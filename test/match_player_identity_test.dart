import 'dart:io';

import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/match_player_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bot identities follow board seats and survive score sorting', () {
    for (final count in [2, 3, 4]) {
      final game = DaketiGame.fromJson({
        'gameId': '4308',
        'players': [
          {'id': 'local', 'name': 'Aqib', 'type': 'human'},
          for (var i = 1; i < count; i++)
            {'id': 'ai-$i', 'name': 'Backend bot $i', 'type': 'ai'},
        ],
      });
      final identities = matchPlayerIdentities(game, 'local', '4308');
      expect(identities.length, count - 1);
      expect(identities.containsKey('local'), isFalse);
      // Reference the original board's seed/seat selection independently.
      var seed = 17;
      for (final unit in '4308'.codeUnits) {
        seed = (seed * 37 + unit) & 0x7fffffff;
      }
      const names = [
        'Ahad',
        'Aiza',
        'Alishba',
        'Anaya',
        'Areeba',
        'Arham',
        'Ayan',
        'Ayesha',
        'Daniyal',
        'Dua',
        'Eshal',
        'Hamza',
        'Hania',
        'Huzaifa',
        'Ibrahim',
        'Inaya',
        'Iqra',
        'Kinza',
        'Laiba',
        'Mahnoor',
        'Meher',
        'Mikaal',
        'Rayyan',
        'Saad',
        'Shahmeer',
        'Shayan',
        'Taha',
        'Zain',
        'Zayan',
        'Zoya'
      ];
      final step = 1 + (seed ~/ 5) % 4;
      final seats =
          count == 2 ? ['ai-1'] : ['ai-2', 'ai-1', if (count == 4) 'ai-3'];
      for (final seat in seats.indexed) {
        final expected = names[(seed + seat.$1 * step) % names.length];
        expect(identities[seat.$2]!.name, expected);
        expect(File(identities[seat.$2]!.avatarAsset).existsSync(), isTrue);
      }
      final rankedIds = seats.reversed;
      final results = matchPlayerIdentities(game, 'local', '4308');
      for (final id in rankedIds) {
        expect(results[id]!.name, identities[id]!.name);
        expect(results[id]!.avatarAsset, identities[id]!.avatarAsset);
      }
    }
  });
}
