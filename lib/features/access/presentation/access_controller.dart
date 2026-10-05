import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_rest_client.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../game/data/game_api_exception.dart';
import '../data/access_models.dart';

final pendingReferralProvider = StateProvider<String?>((ref) => null);

class AccessState {
  const AccessState(
      {this.loading = false,
      this.waitlist,
      this.referrals = const [],
      this.error});
  final bool loading;
  final WaitlistStatus? waitlist;
  final List<ReferralPerson> referrals;
  final String? error;
}

final accessControllerProvider =
    StateNotifierProvider<AccessController, AccessState>((ref) {
  final token = ref.watch(authControllerProvider.select((s) => s.token));
  return AccessController(ref.watch(authRestClientProvider), token,
      onUnauthorized: () =>
          ref.read(authControllerProvider.notifier).expireSession());
});

class AccessController extends StateNotifier<AccessState> {
  AccessController(this.api, this.token, {required this.onUnauthorized})
      : super(const AccessState()) {
    if (token != null) unawaited(refresh(join: true));
  }
  final AuthRestClient api;
  final String? token;
  final Future<void> Function() onUnauthorized;
  Future<void>? _refreshing;

  Future<void> refresh({bool join = false}) {
    return _refreshing ??=
        _refresh(join: join).whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh({required bool join}) async {
    if (token == null) return;
    state = AccessState(
        loading: true, waitlist: state.waitlist, referrals: state.referrals);
    try {
      if (join) await api.request('POST', '/api/waitlist/join', token: token);
      final data = await api.request('GET', '/api/waitlist/me', token: token);
      final waitlist = WaitlistStatus.fromJson(
          Map<String, dynamic>.from(data['waitlist'] as Map));
      if (!mounted) return;
      state = AccessState(waitlist: waitlist, referrals: state.referrals);
    } catch (error) {
      if (!mounted) return;
      if (error is GameApiException && error.statusCode == 401) {
        await onUnauthorized();
      }
      if (mounted) {
        state = AccessState(
            waitlist: state.waitlist,
            referrals: state.referrals,
            error: error is GameApiException
                ? error.message
                : 'Unable to refresh access. Check your connection and retry.');
      }
    }
  }

  Future<void> loadReferrals() async {
    if (token == null) return;
    try {
      final data = await api.request('GET', '/api/referrals/me', token: token);
      if (!mounted) return;
      state = AccessState(
          waitlist: state.waitlist,
          referrals: (data['referrals'] as List? ?? [])
              .whereType<Map>()
              .map((v) => ReferralPerson.fromJson(Map<String, dynamic>.from(v)))
              .toList());
    } catch (error) {
      if (!mounted) return;
      if (error is GameApiException && error.statusCode == 401) {
        await onUnauthorized();
      }
      if (mounted) {
        state = AccessState(
            waitlist: state.waitlist,
            referrals: state.referrals,
            error: error is GameApiException
                ? error.message
                : 'Unable to load referrals. Please retry.');
      }
    }
  }

  Future<bool> checkEligibility() async {
    if (token == null) {
      return true; // The guide explicitly preserves guest play.
    }
    try {
      final data =
          await api.request('GET', '/api/play/eligibility', token: token);
      if (!mounted) return false;
      final allowed = data['canPlay'] == true;
      if (!allowed) unawaited(refresh());
      return allowed;
    } on GameApiException catch (error) {
      if (mounted && (error.statusCode == 401 || error.statusCode == 404)) {
        await onUnauthorized();
      }
      rethrow;
    }
  }
}
