import 'package:daketi_phase1_modular/features/game/domain/models/turn_steal_counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only third stolen card triggers animation, resets for next turn', () {
    final counter = TurnStealCounter();
    expect(counter.add(1), isFalse);
    expect(counter.add(1), isFalse);
    expect(counter.add(1), isTrue);
    expect(counter.add(1), isFalse);
    counter.reset();
    expect(counter.add(1), isFalse);
    expect(counter.add(2), isTrue);
  });
  test('a grouped three-card steal triggers once; empty updates do not count',
      () {
    final counter = TurnStealCounter();
    expect(counter.add(0), isFalse);
    expect(counter.add(3), isTrue);
    expect(counter.add(3), isFalse);
  });
}
