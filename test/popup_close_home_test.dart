import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/core/routes/game_popup_route.dart';
import 'package:flutter/material.dart';
import 'package:daketi_phase1_modular/core/routes/fixed_background_page_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard and option routes have no foreground transition delay', () {
    final home = FixedBackgroundPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.home),
      builder: (_) => const SizedBox());
    expect(home.transitionDuration, Duration.zero);
    for (final name in [AppRoutes.profile, AppRoutes.support, AppRoutes.settings,
      AppRoutes.menu, AppRoutes.multiplayer, AppRoutes.results]) {
      final popup = GamePopupRoute<void>(settings: RouteSettings(name: name), child: const SizedBox());
      expect(popup.transitionDuration, Duration.zero);
      expect(popup.reverseTransitionDuration, Duration.zero);
    }
  });
  for (final route in [AppRoutes.menu, AppRoutes.settings, AppRoutes.results]) {
    testWidgets('$route close returns Home and removes previous game/page', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        routes: {AppRoutes.home: (_) => const Scaffold(body: Text('Home destination'))},
        home: const Scaffold(body: Text('Previous screen')),
      ));
      nav.currentState!.push(GamePopupRoute<void>(settings: RouteSettings(name: route), child: const SizedBox()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close popup'));
      await tester.pumpAndSettle();
      expect(find.text('Home destination'), findsOneWidget);
      expect(find.text('Previous screen'), findsNothing);
      expect(nav.currentState!.canPop(), isFalse);
    });
  }
}
