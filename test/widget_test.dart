import 'package:daketi_phase1_modular/app/daketi_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Daketi app renders its splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DaketiApp()));

    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });
}
