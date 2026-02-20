import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/desktop_app_shell.dart';
import 'package:hentai_library/presentation/ui/mobile/shell/mobile_app_shell.dart';

class AdaptiveAppShell extends StatelessWidget {
  final Widget routeChild;
  const AdaptiveAppShell({super.key, required this.routeChild});

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return DesktopAppShell(routeChild: routeChild);
    }
    return MobileAppShell(routeChild: routeChild);
  }
}
