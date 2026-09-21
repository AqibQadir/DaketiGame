import 'package:daketi_phase1_modular/features/game/presentation/widgets/table_card_slots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('capture and server reorder preserve all surviving positions', () {
    final slots = TableCardSlots()..update(['QC', '7S', '3C', 'QD', '6C']);
    final seven = slots['7S'];
    final queen = slots['QD'];
    slots.update(['QD', '7S']);
    expect(slots['7S'], seven);
    expect(slots['QD'], queen);
    slots.update(['TS', 'QD', '7S']);
    expect(slots['TS'], 0);
    expect(slots['7S'], seven);
    expect(slots['QD'], queen);
  });

  test('additional rows and empty table reuse do not collide', () {
    final slots = TableCardSlots()..update(['a', 'b', 'c', 'd', 'e']);
    slots.update(['f', 'e', 'd', 'c', 'b', 'a']);
    expect(slots['a'], 0);
    expect(slots['e'], 4);
    expect(slots['f'], 5);
    slots.update([]);
    slots.update(['g']);
    expect(slots['g'], 0);
  });
}
