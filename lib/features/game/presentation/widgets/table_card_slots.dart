/// Keeps surviving cards in their slots even when server order changes.
/// New cards occupy vacant slots; captures never compact the table.
class TableCardSlots {
  final Map<String, int> _slots = {};

  int operator [](String cardId) => _slots[cardId]!;

  void update(Iterable<String> cardIds) {
    final ids = cardIds.toList(growable: false);
    final present = ids.toSet();
    _slots.removeWhere((id, _) => !present.contains(id));
    final occupied = _slots.values.toSet();
    for (final id in ids) {
      if (_slots.containsKey(id)) continue;
      var slot = 0;
      while (occupied.contains(slot)) {
        slot++;
      }
      _slots[id] = slot;
      occupied.add(slot);
    }
  }
}
