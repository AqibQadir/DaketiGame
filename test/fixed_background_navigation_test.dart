import 'package:daketi_phase1_modular/core/routes/fixed_background_page_route.dart';
import 'package:daketi_phase1_modular/core/widgets/game_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigation switches immediately while background stays fixed',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: GameBackground(child: SizedBox()))));
    navigator.currentState!.push(FixedBackgroundPageRoute<void>(
        builder: (_) => const Scaffold(
            body: GameBackground(
                child: Center(
                    child: SizedBox(
                        key: ValueKey('foreground'),
                        width: 100,
                        height: 50))))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final background = tester.getRect(find.byType(Image).last);
    final foreground = tester.getRect(find.byKey(const ValueKey('foreground')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(find.byType(Image).last), background);
    expect(tester.getRect(find.byKey(const ValueKey('foreground'))).left,
        foreground.left);
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getRect(find.byType(Image).last), background);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
