import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/presentation/controllers/game_controller.dart';

/// Uses the server's live connected-player count, never demo friend presence.
final onlinePlayersProvider = FutureProvider.autoDispose<int>((ref) async {
  final refresh = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(refresh.cancel);
  final stats = await ref.watch(gameRestClientProvider).getServerStats();
  final count = stats['connectedPlayers'];
  if (count is! int || count < 0) {
    throw const FormatException('Invalid connected-player count');
  }
  return count;
});
