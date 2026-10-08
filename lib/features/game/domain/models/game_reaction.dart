/// Fixed reaction vocabulary shared by the picker and room-message receiver.
enum GameReaction {
  laugh('😂', 'Oye hoye, maal gaya!'),
  challenge('😎', 'Himmat ae? Chaal chal!'),
  surprise('😱', 'Yeh kya kar diya!'),
  cheeky('😏', 'Bas inni si game?'),
  tea('☕', 'Chai pee, hosh kar!'),
  champion('🔥', 'Ustaad nu na chher!');

  const GameReaction(this.emoji, this.caption);
  final String emoji;
  final String caption;

  // Uses the existing room-message relay; never trust a sender in the text.
  String encode(int nonce) => 'daketi:reaction:v1:$name:$nonce';

  static GameReaction? decode(String message) {
    final parts = message.split(':');
    if (parts.length != 5 ||
        parts.take(3).join(':') != 'daketi:reaction:v1' ||
        int.tryParse(parts[4]) == null) {
      return null;
    }
    for (final reaction in values) {
      if (reaction.name == parts[3]) return reaction;
    }
    return null;
  }
}
