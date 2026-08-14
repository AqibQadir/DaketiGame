import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/game_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the complete documented game state', () {
    final game = DaketiGame.fromJson({
      'gameId': '0472',
      'status': 'playing',
      'players': [
        {
          'id': 'p1',
          'name': 'Player',
          'type': 'human',
          'hand': ['AH'],
          'handCount': 1,
          'stack': ['KD'],
          'stackCount': 1,
          'topCard': 'KD',
          'score': 25,
          'isConnected': true,
          'isReady': true,
        },
      ],
      'maxPlayers': 4,
      'table': ['2H'],
      'deckCount': 28,
      'currentTurn': 0,
      'currentPlayerId': 'p1',
      'turnStartTime': 1234567890,
      'turnTimeLimit': 30,
      'dealer': 0,
      'round': 1,
      'protectedValues': ['K'],
      'winner': null,
    });

    expect(game.gameId, '0472');
    expect(game.status, DaketiGameStatus.playing);
    expect(game.players.single.hand.single.id, 'AH');
    expect(game.players.single.topCard?.id, 'KD');
    expect(game.protectedValues, ['K']);
    expect(game.turnTimeLimit, 30);
  });

  test('parses each documented legal action', () {
    const types = {
      'capture_table': GameActionType.captureTable,
      'steal_opponent': GameActionType.stealOpponent,
      'extend_stack': GameActionType.extendStack,
      'discard': GameActionType.discard,
    };

    for (final entry in types.entries) {
      final action = GameAction.fromJson({
        'type': entry.key,
        'cardId': 'AH',
        'targetPlayerId': 'p2',
      });
      expect(action.type, entry.value);
      expect(action.cardId, 'AH');
    }
  });
}
