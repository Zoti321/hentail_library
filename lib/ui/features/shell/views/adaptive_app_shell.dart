import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/ui/features/shell/views/desktop/desktop_app_shell.dart';
import 'package:hentai_library/ui/features/shell/views/mobile/mobile_app_shell.dart';

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
