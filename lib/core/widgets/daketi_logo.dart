import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum DaketiLogoType {
  whiteOrange,
  white,
  orange,
  black,
  primary,
}

class DaketiLogo extends StatelessWidget {
  const DaketiLogo({
    super.key,
    this.type = DaketiLogoType.whiteOrange,
    this.width = 300,
    this.height,
    this.fit = BoxFit.contain,
  });

  final DaketiLogoType type;
  final double width;
  final double? height;
  final BoxFit fit;

  String get _assetPath {
    switch (type) {
      case DaketiLogoType.whiteOrange:
        return 'assets/images/daketi_logo_white_orange.svg';

      case DaketiLogoType.white:
        return 'assets/images/daketi_logo_white.svg';

      case DaketiLogoType.orange:
        return 'assets/images/daketi_logo_orange.svg';

      case DaketiLogoType.black:
        return 'assets/images/daketi_logo_black.svg';

      case DaketiLogoType.primary:
        return 'assets/images/daketi_logo_primary.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
