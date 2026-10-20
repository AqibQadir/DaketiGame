import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/room_city_picker.dart';
import 'package:daketi_phase1_modular/features/tables/domain/table_room.dart';

void main() {
  testWidgets('room city scroller selects the first and last supplied cities',
      (tester) async {
    TableRoom? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
      width: 350,
      child: StatefulBuilder(
          builder: (_, setState) => RoomCityPicker(
              selected: selected,
              onChanged: (city) => setState(() => selected = city))),
    )))));
    await tester.tap(find.text('LAHORE'));
    await tester.pumpAndSettle();
    expect(selected, TableRoom.oldLahore);
    await tester.scrollUntilVisible(find.text('HYDERABAD'), 250,
        scrollable: find.byType(Scrollable));
    await tester.tap(find.text('HYDERABAD'));
    await tester.pumpAndSettle();
    expect(selected, TableRoom.hyderabad);
    expect(tester.takeException(), isNull);
  });
}
