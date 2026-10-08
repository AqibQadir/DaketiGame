import 'package:daketi_phase1_modular/core/widgets/game_viewport.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/game_reaction.dart';
import 'package:daketi_phase1_modular/features/game/presentation/controllers/game_controller.dart';
import 'package:daketi_phase1_modular/features/game/presentation/screens/game_screen.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/game_reactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'multiplayer_game_flow_test.dart' show FlowController;

class ReactionController extends FlowController {
  ReactionController({super.count = 4}) : super(resumed: true);
  final sent = <String>[];
  bool succeeds = true;
  @override
  Future<bool> sendChatMessage(String message) async {
    sent.add(message);
    return succeeds;
  }

  void receive(String sender, String message) {
    final entry = RoomChatMessage(
        senderId: sender,
        senderName: 'Human',
        message: message,
        sentAt: DateTime.now());
    state = state.copyWith(
        chatMessages: [...state.chatMessages, entry], latestChatMessage: entry);
  }

  void history(String sender, String message) {
    state = state.copyWith(chatMessages: [
      RoomChatMessage(
          senderId: sender,
          senderName: 'Human',
          message: message,
          sentAt: DateTime.now())
    ]);
  }
}

Future<void> mountGame(
    WidgetTester tester, ReactionController controller) async {
  await tester.binding.setSurfaceSize(const Size(844, 390));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ProviderScope(
    overrides: [gameControllerProvider.overrideWith((ref) => controller)],
    child: const MaterialApp(home: GameScreen()),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets(
      'picker replaces text chat and local echo does not extend four seconds',
      (tester) async {
    final controller = ReactionController();
    await mountGame(tester, controller);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('reaction-button')));
    await tester.pump();
    expect(find.byType(ReactionPicker), findsOneWidget);
    expect(find.byKey(const ValueKey('reaction-option-laugh')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reaction-option-laugh')));
    await tester.pump();
    expect(find.byType(ReactionPicker), findsNothing);
    expect(GameReaction.decode(controller.sent.single), GameReaction.laugh);
    expect(find.byKey(const ValueKey('player-reaction-p1')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    controller.receive('p1', controller.sent.single);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byType(PlayerReactionBubble), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(PlayerReactionBubble), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final count in [2, 3, 4]) {
    testWidgets(
        'remote reactions follow seats and expire independently for $count players',
        (tester) async {
      final controller = ReactionController(count: count);
      await mountGame(tester, controller);
      final top = count == 2 ? 'p0' : 'p${3 % count}';
      controller.receive(top, GameReaction.challenge.encode(42));
      await tester.pump();
      final topBubble = find.byKey(ValueKey('player-reaction-$top'));
      expect(topBubble, findsOneWidget);
      final board = tester.getRect(find.byKey(GameViewport.canvasKey));
      final bubble = tester.getRect(topBubble);
      expect(board.contains(bubble.topLeft), isTrue);
      expect(board.contains(bubble.bottomRight), isTrue);
      await tester.pump(const Duration(seconds: 2));
      if (count > 2) {
        controller.receive('p2',
            GameReaction.tea.encode(DateTime.now().microsecondsSinceEpoch));
        await tester.pump();
        expect(find.byType(PlayerReactionBubble), findsNWidgets(2));
      }
      await tester.pump(const Duration(seconds: 2));
      expect(topBubble, findsNothing);
      if (count > 2) {
        expect(
            find.byKey(const ValueKey('player-reaction-p2')), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
      }
      expect(find.byType(PlayerReactionBubble), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'unknown senders and old messages are ignored and picker dismisses',
      (tester) async {
    final controller = ReactionController();
    await mountGame(tester, controller);
    controller.receive('outsider',
        GameReaction.laugh.encode(DateTime.now().microsecondsSinceEpoch));
    controller.history(
        'p0', GameReaction.laugh.encode(DateTime.now().microsecondsSinceEpoch));
    controller.receive('p0', 'hello');
    await tester.pump();
    expect(find.byType(PlayerReactionBubble), findsNothing);
    await tester.tap(find.byKey(const ValueKey('reaction-button')));
    await tester.pump();
    await tester.tapAt(const Offset(300, 200));
    await tester.pump();
    expect(find.byType(ReactionPicker), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
