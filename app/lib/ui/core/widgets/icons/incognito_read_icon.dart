import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IncognitoReadIcon extends StatelessWidget {
  const IncognitoReadIcon({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/incognito.svg',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
