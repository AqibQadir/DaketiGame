import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daketi_phase1_modular/core/constants/app_colors.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/focused_card_carousel.dart';
import 'package:daketi_phase1_modular/features/tables/presentation/widgets/table_card.dart';

void main() {
  testWidgets('only the centered unlocked card gets orange; badges stay hidden',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FocusedCardCarousel(
      itemCount: 4,
      label: 'Tables',
      pageKey: const ValueKey('test-pages'),
      itemBuilder: (_, index) => TableCard(
          title: 'Card $index',
          subtitle: '',
          buyIn: '100',
          reward: '100',
          badge: index == 1 ? 'POPULAR' : 'STARTER',
          locked: index == 2,
          wholeCardClickable: true,
          onTap: () {}),
    ))));
    await tester.pumpAndSettle();
    Color border(int index) {
      final card = find
          .byWidgetPredicate((w) => w is TableCard && w.title == 'Card $index')
          .first;
      final frame = find
          .descendant(
              of: card,
              matching: find.byWidgetPredicate((w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).border != null))
          .first;
      return ((tester.widget<Container>(frame).decoration as BoxDecoration)
              .border as Border)
          .top
          .color;
    }

    expect(find.text('POPULAR'), findsNothing);
    expect(find.text('STARTER'), findsNothing);
    expect(border(0), AppColors.orange);
    expect(border(1), isNot(AppColors.orange));
    final controller = tester
        .widget<PageView>(find.byKey(const ValueKey('test-pages')))
        .controller!;
    controller.jumpToPage(controller.initialPage + 1);
    await tester.pumpAndSettle();
    expect(border(0), isNot(AppColors.orange));
    expect(border(1), AppColors.orange);
    controller.jumpToPage(controller.initialPage + 2);
    await tester.pumpAndSettle();
    expect(border(1), isNot(AppColors.orange));
    expect(border(2), isNot(AppColors.orange));
    expect(tester.takeException(), isNull);
  });
}
