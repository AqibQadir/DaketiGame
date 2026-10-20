import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Opening allowances for the UI, independent of card/bonus leaderboard scores.
/// Replace with an authoritative wallet response when that API is supplied.
class StartingBalance {
  const StartingBalance({required this.coins, required this.rupees});
  final int coins;
  final int rupees;
}

final startingBalanceProvider = Provider<StartingBalance>((ref) {
  final signedIn =
      ref.watch(authControllerProvider.select((s) => s.isAuthenticated));
  return signedIn
      ? const StartingBalance(coins: 500, rupees: 10)
      : const StartingBalance(coins: 200, rupees: 0);
});
