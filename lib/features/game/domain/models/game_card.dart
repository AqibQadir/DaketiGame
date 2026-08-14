class GameCard {
  const GameCard({required this.id, required this.value, required this.suit});

  final String id;
  final String value;
  final String suit;

  bool get isHidden => id == 'hidden';
  bool get isRed => suit == 'H' || suit == 'D';

  String get suitSymbol {
    return switch (suit) {
      'H' => '♥',
      'D' => '♦',
      'C' => '♣',
      'S' => '♠',
      _ => '',
    };
  }

  factory GameCard.fromId(String id) {
    if (id == 'hidden') {
      return const GameCard(id: 'hidden', value: '', suit: '');
    }
    if (id.length != 2) {
      throw FormatException('Invalid card id: $id');
    }
    const values = {
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'T',
      'J',
      'Q',
      'K',
      'A'
    };
    const suits = {'H', 'D', 'C', 'S'};
    final value = id[0].toUpperCase();
    final suit = id[1].toUpperCase();
    if (!values.contains(value) || !suits.contains(suit)) {
      throw FormatException('Invalid card id: $id');
    }
    return GameCard(id: '$value$suit', value: value, suit: suit);
  }
}
