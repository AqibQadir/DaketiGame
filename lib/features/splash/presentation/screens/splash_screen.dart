import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/game_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.terms,
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                        'Terms & Conditions',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.privacy,
                        );
                      },
                      child: const Text(
                        'Privacy Policy',
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
