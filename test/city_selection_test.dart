import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/tables/domain/table_room.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/screens/tables_screen.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/city_table_cards.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'full width city carousel grows the focused card and retains navigation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute, home: TablesScreen())));
    await tester.pumpAndSettle();
    final pages = find.byKey(const ValueKey('city-pages'));
    expect(tester.getSize(pages).width, 844);
    double scale(int index) => tester
        .widget<Transform>(find.byKey(ValueKey('Cities-scale-$index')))
        .transform
        .storage[0];
    final previousCity = find.byWidgetPredicate(
        (w) => w is TableCard && w.title == TableRoom.values.last.title);
    expect(previousCity, findsOneWidget);
    expect(tester.getRect(previousCity).left, lessThan(422));
    expect(scale(0), 1);
    expect(scale(1), lessThan(scale(0)));
    await tester.drag(pages, const Offset(-350, 0));
    await tester.pumpAndSettle();
    final controller = tester.widget<PageView>(pages).controller!;
    final selected = controller.page!.round() % TableRoom.values.length;
    expect(selected, greaterThan(0));
    expect(scale(selected), 1);
    expect(scale(selected - 1), lessThan(1));
    controller.jumpToPage(2);
    await tester.pumpAndSettle();
    for (final city in TableRoom.values.take(5)) {
      final card = find
          .byWidgetPredicate((w) => w is TableCard && w.title == city.title);
      expect(card, findsOneWidget);
      final bounds = tester.getRect(card);
      expect(bounds.right, greaterThan(0));
      expect(bounds.left, lessThan(844));
    }
    for (var i = 0; i < TableRoom.values.length; i++) {
      controller.jumpToPage(i);
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate(
              (w) => w is TableCard && w.title == TableRoom.values[i].title),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    final city = TableRoom.values.last;
    await tester.tap(
        find.byWidgetPredicate((w) => w is TableCard && w.title == city.title));
    await tester.pumpAndSettle();
    expect(find.byType(CityTableCards), findsNothing);
    expect(
        ModalRoute.of(tester.element(find.byType(TableCard).first))!
            .settings
            .name,
        AppRoutes.tableRoom);
    expect(
        tester
            .widgetList<TableCard>(find.byType(TableCard))
            .where((card) => !card.locked)
            .single
            .title,
        'ADDA');
    final tiers =
        tester.widget<PageView>(find.byKey(const ValueKey('table-tier-pages')));
    tiers.controller!.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close tables'));
    await tester.pumpAndSettle();
    expect(find.text('10 / 10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
