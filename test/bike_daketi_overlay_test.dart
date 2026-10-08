import 'package:daketi_phase1_modular/features/game/presentation/widgets/bike_daketi_overlay.dart';
import 'package:daketi_phase1_modular/features/game/domain/models/game_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bike Daketi shows the steal stamp and completes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BikeDaketiOverlay(
                source: const Offset(700, 180),
                destination: const Offset(400, 330),
                cardCount: 3,
                cards: [
                  GameCard.fromId('7H'),
                  GameCard.fromId('KS'),
                  GameCard.fromId('AC'),
                ],
                onComplete: () => completed = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('DAKETI!'), findsOneWidget);
    final assets = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      if (image.image case final AssetImage asset) {
        expect(assets, contains(asset.assetName));
      }
    }
    expect(find.text('3 CARDS STOLEN · MAAL GAYA!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 700));
    expect(completed, isTrue);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('victim sees supplied GIF and a one-card loss message',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var completed = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Stack(children: [
      BikeDaketiOverlay(
        source: const Offset(400, 330),
        destination: const Offset(515, 70),
        cardCount: 1,
        cards: [GameCard.fromId('7H')],
        isLocalVictim: true,
        onComplete: () => completed = true,
      ),
    ]))));
    final image = tester.widgetList<Image>(find.byType(Image)).firstWhere(
          (image) =>
              image.image is AssetImage &&
              (image.image as AssetImage).assetName ==
                  'assets/images/steal_bike_animation.gif',
        );
    expect(image.width, 280);
    await tester.pump(const Duration(milliseconds: 1550));
    expect(find.text('YOU WERE ROBBED!'), findsOneWidget);
    expect(find.text('1 CARD TAKEN FROM YOUR STACK'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 700));
    expect(completed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
