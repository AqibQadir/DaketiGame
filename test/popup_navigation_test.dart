import 'package:daketi_phase1_modular/features/tables/presentation/screens/table_room_screen.dart';
import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/core/routes/game_popup_route.dart';
import 'package:daketi_phase1_modular/features/home/presentation/screens/home_screen.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/guest_name_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'menu closes over start page and guest proceeds to city selection',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final nav = GlobalKey<NavigatorState>();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            navigatorKey: nav,
            initialRoute: AppRoutes.welcome,
            onGenerateRoute: AppRouter.onGenerateRoute)));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byTooltip('Close popup'), findsNothing);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    nav.currentState!.pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('TUTORIAL'), findsNothing);
    await tester.tap(find.byTooltip('Close popup'));
    await tester.pumpAndSettle();
    nav.currentState!.pushNamed(AppRoutes.menu);
    await tester.pumpAndSettle();
    final close = find.byTooltip('Close popup');
    expect(close, findsOneWidget);
    expect(ModalRoute.of(tester.element(close)), isA<GamePopupRoute>());
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(nav.currentState!.canPop(), isFalse);
    expect(find.text('PLAY AS GUEST'), findsNothing);
    nav.currentState!.pushNamed(AppRoutes.guestName);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Guest tester');
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('Select age'), findsOneWidget);
    expect(find.text('Select gender'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prefer not to say').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('GUEST TESTER'), findsOneWidget);
    expect(find.text('LAHORI\nBAAZI'), findsOneWidget);
    expect(find.text('KARACHI\nSCENZ'), findsOneWidget);
    expect(find.text('PINDI DA\nADDA'), findsOneWidget);
    expect(find.text('MULTANI\nMEHFIL'), findsOneWidget);
    expect(find.text('START GAME'), findsNothing);
    await tester.tap(find.text('ENTER MATCH').first);
    await tester.pumpAndSettle();
    expect(find.byType(TableRoomScreen), findsOneWidget);
    expect(find.text('ADDA'), findsOneWidget);
    expect(find.text('BAAZI'), findsOneWidget);
    expect(find.text('PLAY AS GUEST'), findsNothing);
    expect(container.read(guestNameProvider), 'Guest tester');
    expect(tester.takeException(), isNull);
  });
}
