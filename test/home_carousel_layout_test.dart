import 'package:daketi_phase1_modular/core/widgets/game_viewport.dart';
import 'package:daketi_phase1_modular/features/home/presentation/screens/home_screen.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:daketi_phase1_modular/features/home/presentation/controllers/online_players_provider.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'profile_setup_gate_test.dart' show FakeAuth;

void main() {
  testWidgets(
      'Home gives city cards full width without guest or shop shortcuts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          onlinePlayersProvider.overrideWith((ref) async => 42),
          authControllerProvider.overrideWith(
              (ref) => FakeAuth(const AuthState(isRestoring: false))),
        ],
        child: MaterialApp(home: const HomeScreen(), routes: {
          AppRoutes.signup: (_) => const Scaffold(body: Text('SIGNUP OPEN'))
        })));
    await tester.pumpAndSettle();
    expect(find.text('GUEST PLAY'), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byIcon(Icons.workspace_premium), findsNothing);
    expect(find.text('42 players online'), findsOneWidget);
    expect(find.text('PLAY WITH FRIENDS'), findsNothing);
    expect(find.byIcon(Icons.groups), findsOneWidget);
    expect(find.byIcon(Icons.storefront), findsNothing);
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('city-pages'))).width, 844);
    expect(find.text('LAHORE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.groups));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Sign up to create or join custom rooms, add friends, and send friend requests.'),
        findsOneWidget);
    expect(find.text('Rs 0'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    await tester.tap(find.text('SIGN UP'));
    await tester.pumpAndSettle();
    expect(find.text('SIGNUP OPEN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home keeps the same relative spacing across phone shapes',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const devices = [
      (
        size: Size(956, 440),
        padding: EdgeInsets.only(left: 62, right: 62, bottom: 21)
      ),
      (size: Size(736, 414), padding: EdgeInsets.zero),
      (size: Size(667, 375), padding: EdgeInsets.zero),
      (size: Size(800, 360), padding: EdgeInsets.zero),
      (size: Size(915, 412), padding: EdgeInsets.only(left: 28)),
    ];
    List<Rect>? reference;
    for (final device in devices) {
      await tester.binding.setSurfaceSize(device.size);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          onlinePlayersProvider.overrideWith((ref) async => 42),
          authControllerProvider.overrideWith(
              (ref) => FakeAuth(const AuthState(isRestoring: false))),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: device.size,
              padding: device.padding,
              viewPadding: device.padding,
              textScaler: TextScaler.linear(1.3),
            ),
            child: const HomeScreen(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final canvas = tester.getRect(find.byKey(GameViewport.canvasKey));
      final elements = [
        find.byKey(const ValueKey('city-pages')),
        find.text('LAHORE'),
        find.byType(CircleAvatar),
        find.byIcon(Icons.groups),
        find.byIcon(Icons.settings),
        find.text('42 players online'),
        find.text('Rs 0'),
      ];
      final positions = elements.map((finder) {
        final rect = tester.getRect(finder);
        return Rect.fromLTWH(
          (rect.left - canvas.left) / canvas.width,
          (rect.top - canvas.top) / canvas.height,
          rect.width / canvas.width,
          rect.height / canvas.height,
        );
      }).toList();
      reference ??= positions;
      for (var i = 0; i < positions.length; i++) {
        expect(positions[i].left, closeTo(reference[i].left, .0001));
        expect(positions[i].top, closeTo(reference[i].top, .0001));
        expect(positions[i].width, closeTo(reference[i].width, .0001));
        expect(positions[i].height, closeTo(reference[i].height, .0001));
      }
      expect(tester.takeException(), isNull, reason: '${device.size}');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
