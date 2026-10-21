import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome controls and tool close retain login input',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: WelcomeScreen(),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byIcon(Icons.facebook), findsNothing);
    expect(find.text('SIGN UP'), findsOneWidget);
    expect(find.text('PLAY AS GUEST'), findsOneWidget);
    final email = tester.getRect(find.byType(TextField).first);
    final password = tester.getRect(find.byType(TextField).last);
    final login = tester.getRect(find.text('LOGIN'));
    expect(email.center.dy, password.center.dy);
    expect(login.center.dy, closeTo(email.center.dy, 1));
    expect(email.right, lessThan(password.left));
    expect(password.right, lessThan(login.left));
    final signup = tester.getRect(find.text('SIGN UP'));
    final guest = tester.getRect(find.text('PLAY AS GUEST'));
    expect(signup.center.dy, closeTo(guest.center.dy, 1));
    expect(signup.top, greaterThan(email.bottom));
    await tester.enterText(find.byType(TextField).first, 'player@example.com');
    for (final icon in [Icons.settings, Icons.support_agent]) {
      await tester.tap(find.byIcon(icon).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close popup'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('player@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
