import 'package:daketi_phase1_modular/core/routes/game_popup_route.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/quests/presentation/screens/side_quests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('missions close button stays above content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => TextButton(
      onPressed: () => Navigator.of(context).push(GamePopupRoute<void>(
        settings: const RouteSettings(name: AppRoutes.sideQuests), child: const SideQuestsScreen())),
      child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byTooltip('Close popup')).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(SideQuestsScreen)).top));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close popup'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
}
