import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/game_button.dart';

class LegalSection {
  const LegalSection(this.title, this.content);
  final String title;
  final String content;
}

class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.buttonText,
    required this.onContinue,
  });

  final String title;
  final String subtitle;
  final List<LegalSection> sections;
  final String buttonText;
  final VoidCallback onContinue;

  void _close(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      onContinue();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GameBackground(
          variant: 1,
          overlayOpacity: .30,
          child: LayoutBuilder(builder: (context, constraints) {
            final scale = math.min(constraints.maxWidth / 870, 1.0);
            final cardWidth = math.min(
              747.0,
              math.max(280.0, constraints.maxWidth - 122 * scale),
            );
            final cardHeight = math.min(
              249.0,
              math.max(190.0, constraints.maxHeight - 144 * scale),
            );
            return Stack(children: [
              Center(
                child: _ReferenceGlassCard(
                  width: cardWidth,
                  height: cardHeight,
                  scale: scale,
                  title: title,
                  body: sections.map((section) => section.content).join(' '),
                  buttonText: buttonText,
                  onContinue: onContinue,
                ),
              ),
              Positioned(
                left: 26 * scale,
                top: 24 * scale,
                child: _ReferenceCloseButton(
                  size: 60 * scale,
                  onTap: () => _close(context),
                ),
              ),
            ]);
          }),
        ),
      );
}

class _ReferenceGlassCard extends StatelessWidget {
  const _ReferenceGlassCard({
    required this.width,
    required this.height,
    required this.scale,
    required this.title,
    required this.body,
    required this.buttonText,
    required this.onContinue,
  });

  final double width;
  final double height;
  final double scale;
  final String title;
  final String body;
  final String buttonText;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(23 * scale),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.fromLTRB(
              44 * scale,
              21 * scale,
              44 * scale,
              20 * scale,
            ),
            decoration: BoxDecoration(
              // Figma reference: black fill at 27% with a glass effect.
              color: const Color(0x45000000),
              borderRadius: BorderRadius.circular(23 * scale),
              border: Border.all(color: const Color(0x4DFFFFFF), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xB3000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21 * scale,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 18 * scale),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .88),
                        fontSize: 14 * scale,
                        height: 1.55,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        letterSpacing: .15,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8 * scale),
              GameButton(
                text: buttonText,
                width: 126 * scale,
                onTap: onContinue,
              ),
            ]),
          ),
        ),
      );
}

class _ReferenceCloseButton extends StatelessWidget {
  const _ReferenceCloseButton({
    required this.onTap,
    required this.size,
  });

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * .17),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1A000000),
              border: Border.all(color: const Color(0x66FFFFFF), width: .8),
            ),
            child: Image.asset(
              AppAssets.closeCross,
              fit: BoxFit.contain,
              color: Colors.white.withValues(alpha: .92),
            ),
          ),
        ),
      );
}
