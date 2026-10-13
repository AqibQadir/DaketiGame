import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/tables/domain/table_room.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/city_table_cards.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('10 supplied cities page into a separate tier screen with close',
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
    expect(TableRoom.values.length, 10);
    expect(TableRoom.values.every((city) => !city.locked), isTrue);
    final firstCardSize = tester.getSize(find.byType(TableCard).first);
    for (var page = 0; page < 3; page++) {
      for (final city in TableRoom.values.skip(page * 4).take(4)) {
        expect(find.text(city.title), findsOneWidget);
      }
      for (final city in TableRoom.values.skip(page * 4).take(4)) {
        final card = find.byWidgetPredicate(
            (widget) => widget is TableCard && widget.title == city.title);
        expect(tester.getSize(card), firstCardSize);
      }
      if (page == 2) {
        final firstCity = find.byWidgetPredicate(
            (widget) => widget is TableCard && widget.title == 'SIALKOT');
        expect(tester.getTopLeft(firstCity).dx,
            tester.getTopLeft(find.byKey(const ValueKey('city-pages'))).dx);
      }
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(tester.takeException(), isNull);
      if (page < 2) {
        await tester.drag(
            find.byKey(const ValueKey('city-pages')), const Offset(-650, 0));
        await tester.pumpAndSettle();
      }
    }
    final pages =
        tester.widget<PageView>(find.byKey(const ValueKey('city-pages')));
    pages.controller!.jumpTo(712 * 1.75);
    await tester.pump();
    final gujranwala = tester.getRect(find.byWidgetPredicate(
        (widget) => widget is TableCard && widget.title == 'GUJRANWALA'));
    final sialkot = tester.getRect(find.byWidgetPredicate(
        (widget) => widget is TableCard && widget.title == 'SIALKOT'));
    expect(sialkot.left - gujranwala.right, closeTo(12, 0.01));
    pages.controller!.jumpToPage(2);
    await tester.pumpAndSettle();
    expect(find.text('SELECT CITY'), findsNothing);
    final cityCard = find.byWidgetPredicate(
        (widget) => widget is TableCard && widget.title == 'HYDERABAD');
    final box = tester.getRect(cityCard);
    await tester.tapAt(box.bottomRight - const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(CityTableCards), findsNothing);
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Image && widget.semanticLabel == 'HYDERABAD'),
        findsOneWidget);
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
    expect(find.text('3 / 3'), findsOneWidget);
  });
}
