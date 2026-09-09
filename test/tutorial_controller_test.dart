import 'package:daketi_phase1_modular/features/tutorial/data/tutorial_storage_service.dart';
import 'package:daketi_phase1_modular/features/tutorial/domain/tutorial_step.dart';
import 'package:daketi_phase1_modular/features/tutorial/presentation/controllers/tutorial_controller.dart';
import 'package:daketi_phase1_modular/features/tutorial/presentation/screens/game_tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('required tutorial steps advance only after target interaction', () {
    final controller = TutorialController();
    addTearDown(controller.dispose);

    controller.next();
    controller.next();
    controller.next();

    expect(controller.step.target, TutorialTarget.handCard);
    expect(controller.canAdvance, isFalse);

    controller.next();
    expect(controller.step.target, TutorialTarget.handCard);

    controller.targetTapped();
    expect(controller.canAdvance, isTrue);
  });

  test('completion is persisted locally', () async {
    final storage = TutorialStorageService();

    expect(await storage.isCompleted(), isFalse);
    await storage.markCompleted();
    expect(await storage.isCompleted(), isTrue);
  });

  testWidgets('tutorial remains usable at common landscape phone sizes',
      (tester) async {
    for (final size in const [Size(844, 390), Size(667, 375)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        const MaterialApp(home: GameTutorialScreen()),
      );
      await tester.pump();

      expect(find.text('STEP 1 OF 10'), findsOneWidget);
      expect(find.text('SKIP TUTORIAL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
