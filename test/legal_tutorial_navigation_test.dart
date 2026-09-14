import 'package:daketi_phase1_modular/core/routes/app_router.dart';
import 'package:daketi_phase1_modular/core/routes/app_routes.dart';
import 'package:daketi_phase1_modular/features/legal/data/legal_acceptance_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('accepting policies opens the first-time tutorial',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          initialRoute: AppRoutes.terms,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );

    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();
    expect(find.text('STEP 1 OF 10'), findsOneWidget);
    expect(await LegalAcceptanceStorage().isAccepted(), isTrue);

    await tester.binding.setSurfaceSize(null);
  });
}
