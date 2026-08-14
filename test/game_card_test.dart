import 'package:daketi_phase1_modular/features/game/domain/models/game_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCard', () {
    test('parses a normal backend card id', () {
      final card = GameCard.fromId('AH');

      expect(card.value, 'A');
      expect(card.suit, 'H');
      expect(card.suitSymbol, '♥');
      expect(card.isRed, isTrue);
      expect(card.isHidden, isFalse);
    });

    test('parses the opponent hidden-card marker', () {
      final card = GameCard.fromId('hidden');

      expect(card.isHidden, isTrue);
    });

    test('rejects malformed card ids', () {
      expect(() => GameCard.fromId('10H'), throwsFormatException);
      expect(() => GameCard.fromId('AZ'), throwsFormatException);
    });
  });
}
