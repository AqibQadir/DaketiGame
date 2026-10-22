import 'package:daketi_phase1_modular/features/game/domain/models/daketi_game.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/game_action.dart';
import 'package:daketi_phase1_modular/features/game/presentation/widgets/fanned_card_hand.dart';
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

class StackReactionController extends ReactionController {
  StackReactionController(int players) : super(count: players) {
    state = state.copyWith(
        game: DaketiGame.fromJson({
      'gameId': '0093',
      'status': 'playing',
      'maxPlayers': players,
      'currentPlayerId': 'p1',
      'deckCount': 20,
      'table': ['3H'],
      'players': List.generate(
          players,
          (i) => {
                'id': 'p$i',
                'name': 'Human $i',
                'hand': i == 1 ? ['9D'] : ['hidden'],
                'handCount': 1,
                'stack': i == 1 ? ['9H'] : [],
                'topCard': i == 1 ? '9H' : null,
                'stackCount': i == 1 ? 1 : 0,
              }),
    }));
  }

  @override
  Future<void> loadAvailableActions() async {
    state = state.copyWith(availableActions: [
      const GameAction(type: GameActionType.extendStack, cardId: '9D'),
      const GameAction(type: GameActionType.discard, cardId: '9D'),
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
  for (final count in [2, 3, 4]) {
    testWidgets(
        'nine reaches own stack without opening reactions ($count players)',
        (tester) async {
      final controller = StackReactionController(count);
      await mountGame(tester, controller);
      await tester.tap(find.byType(FannedCardHand));
      await tester.pump();
      final pile = find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName.endsWith('/Hearts/9.png'));
      expect(pile, findsOneWidget);
      final smiley =
          tester.getRect(find.byKey(const ValueKey('reaction-button')));
      expect(smiley.overlaps(tester.getRect(pile)), isFalse);
      final avatar =
          tester.getRect(find.byKey(const ValueKey('local-profile-image')));
      expect(smiley.center.dx, greaterThan(avatar.center.dx));
      expect(smiley.center.dy, greaterThan(avatar.center.dy));
      expect(smiley.overlaps(avatar), isTrue);
      // This is the part of the pile that used to sit underneath the smiley.
      final canvas =
          tester.renderObject<RenderBox>(find.byKey(GameViewport.canvasKey));
      await tester.tapAt(canvas.localToGlobal(const Offset(321, 326)));
      await tester.pump();
      expect(controller.performed?.type, GameActionType.extendStack);
      expect(controller.performed?.cardId, '9D');
      expect(find.byType(ReactionPicker), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('match menu has themed settings and leave actions only',
      (tester) async {
    await mountGame(tester, ReactionController());
    await tester.tap(find.byTooltip('Match menu'));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Support'), findsNothing);
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'LEAVE MATCH'));
    await tester.pumpAndSettle();
    expect(find.text('LEAVE MATCH?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

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
