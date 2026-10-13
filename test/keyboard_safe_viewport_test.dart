import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/room_code_input.dart';
import 'package:daketi_phase1_modular/features/support/presentation/screens/report_issue_screen.dart';
import 'package:daketi_phase1_modular/core/widgets/keyboard_safe_viewport.dart';
import 'package:daketi_phase1_modular/core/widgets/game_styled_dialog.dart';
import 'package:daketi_phase1_modular/features/auth/data/auth_rest_client.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/controllers/auth_controller.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/screens/login_screen.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/screens/signup_screen.dart';
import 'package:daketi_phase1_modular/features/auth/presentation/screens/guest_name_screen.dart';
import 'api_guide_integration_test.dart' show MemoryAuthStorage, jsonResponse;

void main() {
  for (final size in [const Size(844, 390), const Size(667, 375)]) {
    for (final screen in <String, Widget>{
      'login': const LoginScreen(),
      'signup': const SignupScreen(),
      'guest': const GuestNameScreen(returnToPrevious: true),
    }.entries) {
      testWidgets(
          '${screen.key} keeps field size and reveals it above keyboard at $size',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        await tester.binding.setSurfaceSize(size);
        addTearDown(() async {
          tester.view.resetViewInsets();
          tester.view.resetDevicePixelRatio();
          await tester.binding.setSurfaceSize(null);
        });
        SharedPreferences.setMockInitialValues({});
        final storage = MemoryAuthStorage()..token = null;
        final api = AuthRestClient(
            baseUrl: 'https://example.test',
            client: MockClient((_) async => jsonResponse({})));
        addTearDown(api.dispose);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              authTokenStorageProvider.overrideWithValue(storage),
              authRestClientProvider.overrideWithValue(api),
            ],
            child: MaterialApp(
              builder: (_, child) => KeyboardSafeViewport(child: child!),
              home: screen.value,
            )));
        await tester.pumpAndSettle();
        final fields = find.byType(EditableText);
        // Move between every field while the keyboard remains open.
        final originalSizes = [
          for (var i = 0; i < fields.evaluate().length; i++)
            tester.getSize(fields.at(i))
        ];
        for (var i = 0; i < originalSizes.length; i++) {
          await tester.showKeyboard(fields.at(i));
          await tester.enterText(fields.at(i), 'test-value-$i');
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          final rect = tester.getRect(fields.at(i));
          expect(tester.getSize(fields.at(i)), originalSizes[i]);
          expect(rect.top, greaterThanOrEqualTo(-1));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 240 + 1));
          expect(tester.widget<EditableText>(fields.at(i)).controller.text,
              'test-value-$i');
          expect(tester.takeException(), isNull);
        }
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        for (var i = 0; i < originalSizes.length; i++) {
          expect(tester.getSize(fields.at(i)), originalSizes[i]);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('long form dialog reveals the last field without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() async {
      tester.view.resetViewInsets();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => KeyboardSafeViewport(child: child!),
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const GameStyledDialog(
                              title: Text('Edit profile'),
                              content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                        decoration:
                                            InputDecoration(labelText: 'Name')),
                                    TextField(
                                        decoration: InputDecoration(
                                            labelText: 'Email')),
                                    TextField(
                                        decoration: InputDecoration(
                                            labelText: 'Date of birth')),
                                  ]),
                            )),
                    child: const Text('Open form'),
                  ))),
    ));
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(EditableText).last);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(EditableText).last);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(136));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'multiline issue field keeps its typing cursor above the keyboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() async {
      tester.view.resetViewInsets();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => KeyboardSafeViewport(child: child!),
      home: const ReportIssueScreen(),
    ));
    await tester.pumpAndSettle();
    final field = find.byType(EditableText);
    await tester.showKeyboard(field);
    await tester.enterText(field, 'An issue to report');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    final state = tester.state<EditableTextState>(field);
    final editable = state.renderEditable;
    final caret =
        editable.getLocalRectForCaret(state.widget.controller.selection.extent);
    final top = editable.localToGlobal(caret.topLeft).dy;
    final bottom = editable.localToGlobal(caret.bottomRight).dy;
    expect(top, greaterThanOrEqualTo(0));
    expect(bottom, lessThanOrEqualTo(136));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final roomCode in [false, true]) {
    testWidgets(
        '${roomCode ? "room code" : "chat composer"} stays visible without shrinking the screen',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      await tester.binding.setSurfaceSize(const Size(667, 375));
      addTearDown(() async {
        tester.view.resetViewInsets();
        tester.view.resetDevicePixelRatio();
        await tester.binding.setSurfaceSize(null);
      });
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        builder: (_, child) => KeyboardSafeViewport(child: child!),
        home: Scaffold(
            body: Column(children: [
          const Expanded(child: Center(child: Text('Content'))),
          if (roomCode)
            RoomCodeInput(controller: controller)
          else
            TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Message')),
        ])),
      ));
      await tester.pumpAndSettle();
      final field = find.byType(EditableText);
      final before = tester.getRect(field);
      await tester.showKeyboard(field);
      await tester.enterText(field, roomCode ? '1234' : 'Hello');
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      final after = tester.getRect(field);
      expect(after.size, before.size);
      expect(after.bottom, lessThanOrEqualTo(136));
      expect(after.top, greaterThanOrEqualTo(0));
      FocusManager.instance.primaryFocus?.unfocus();
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(tester.getRect(field), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
