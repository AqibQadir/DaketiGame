import 'package:daketi_phase1_modular/features/profile/presentation/screens/profile_screen.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/auth/domain/auth_user.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_token_storage.dart';
import 'package:daketi_phase1_modular/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProfileController extends AuthController {
  _ProfileController(AuthRestClient client)
      : super(client: client, storage: AuthTokenStorage());

  @override
  Future<void> restoreSession() async {
    state = const AuthState(
      isRestoring: false,
      user: AuthUser(
          id: 'preview',
          name: 'Qamar Zaman',
          email: 'qamar@zamedia.de',
          emailVerified: true,
          role: 'user',
          createdAt: null),
      stats: AuthStats(gamesWon: 100, gamesPlayed: 125000),
    );
  }
}

void main() {
  testWidgets('profile matches both menu states and opens editing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fonts = FontLoader('Dirty Brush')
      ..addFont(rootBundle.load('assets/fonts/DirtyBrush-Regular.ttf'));
    await fonts.load();
    final client = AuthRestClient(baseUrl: 'http://localhost');
    addTearDown(client.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith((ref) => _ProfileController(client)),
        ],
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const RepaintBoundary(
                key: ValueKey('profile-preview'), child: ProfileScreen()))));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('125,000'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Profile options'));
    await tester.pumpAndSettle();
    expect(find.text('HISTORY'), findsNothing);
    expect(find.text('EDIT'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('EDIT').last);
    await tester.pumpAndSettle();
    expect(find.text('EDIT PROFILE'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('HISTORY'), findsOneWidget);
  });
}
