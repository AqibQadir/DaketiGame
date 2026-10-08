import 'package:daketi_phase1_modular/core/widgets/game_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('loading retains artwork and dimensions and blocks taps', (tester) async {
    var taps = 0;
    Widget button(bool loading) => MaterialApp(home: Center(child: GameButton(
      text: 'Join room', isLoading: loading, onTap: () => taps++)));
    await tester.pumpWidget(button(false));
    final size = tester.getSize(find.byType(GameButton));
    final art = tester.widget<Image>(find.byType(Image));
    await tester.tap(find.byType(GameButton));
    expect(taps, 1);
    await tester.pumpWidget(button(true));
    expect(tester.getSize(find.byType(GameButton)), size);
    expect(tester.widget<Image>(find.byType(Image)).image, art.image);
    expect(tester.widget<Image>(find.byType(Image)).color, art.color);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(GameButton));
    expect(taps, 1);
  });
}
