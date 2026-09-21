/// Tracks stolen cards across consecutive moves within one player's turn.
class TurnStealCounter {
  int _cards = 0;

  /// True only when this move reaches the third stolen card for the first time.
  bool add(int cards) {
    if (cards <= 0) return false;
    final previous = _cards;
    _cards += cards;
    return previous < 3 && _cards >= 3;
  }

  void reset() => _cards = 0;
}
