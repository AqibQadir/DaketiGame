import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/tables/domain/table_room.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/city_table_cards.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('20 open cities page into a separate tier screen with close',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const Scaffold(
          body: Center(
              child: SizedBox(
        width: 712,
        height: 245,
        child: CityTableCards(),
      ))),
    )));
    await tester.pumpAndSettle();
    expect(TableRoom.values.length, 20);
    expect(TableRoom.values.every((city) => !city.locked), isTrue);
    for (var page = 0; page < 5; page++) {
      for (final city in TableRoom.values.skip(page * 4).take(4)) {
        expect(find.text(city.title), findsOneWidget);
      }
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(tester.takeException(), isNull);
      if (page < 4) {
        await tester.drag(
            find.byKey(const ValueKey('city-pages')), const Offset(-650, 0));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(find.text('SELECT CITY').last);
    await tester.pumpAndSettle();
    expect(find.byType(CityTableCards), findsNothing);
    expect(find.text('MUZAFFARABAD'), findsOneWidget);
    expect(find.byTooltip('Close tables'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    final cards = tester.widgetList<TableCard>(find.byType(TableCard)).toList();
    expect(cards.where((card) => !card.locked).single.title, 'ADDA');
    expect(find.byIcon(Icons.lock), findsNWidgets(3));
    final route = ModalRoute.of(tester.element(find.byType(TableCard).first))!;
    expect(route.settings.name, AppRoutes.tableRoom);
    expect(route.opaque, isTrue);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close tables'));
    await tester.pumpAndSettle();
    expect(find.byType(CityTableCards), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
  });
}
