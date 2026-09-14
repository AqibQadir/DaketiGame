import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../legal/data/legal_acceptance_storage.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  ProviderSubscription<AuthState>? _authSubscription;
  bool _minimumDisplayElapsed = false;
  bool? _legalAccepted;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _authSubscription = ref.listenManual<AuthState>(
      authControllerProvider,
      (_, __) => _tryNavigate(),
      fireImmediately: true,
    );
    _loadStartupState();
  }

  Future<void> _loadStartupState() async {
    final accepted = await LegalAcceptanceStorage().isAccepted();
    if (!mounted) return;
    _legalAccepted = accepted;
    _timer = Timer(const Duration(seconds: 3), () {
      _minimumDisplayElapsed = true;
      _tryNavigate();
    });
  }

  void _tryNavigate() {
    if (!mounted ||
        _navigated ||
        !_minimumDisplayElapsed ||
        _legalAccepted == null) {
      return;
    }
    final auth = ref.read(authControllerProvider);
    if (auth.isRestoring) return;
    _navigated = true;
    final route = _legalAccepted! == false
        ? AppRoutes.terms
        : auth.isAuthenticated
            ? AppRoutes.home
            : AppRoutes.welcome;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameBackground(
        variant: 1,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/images/daketi_logo_white_orange.svg',
                  width: 320,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 25,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.terms,
                        );
                      },
                      child: const Text(
                        'Terms & Conditions & Privacy Policy',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
