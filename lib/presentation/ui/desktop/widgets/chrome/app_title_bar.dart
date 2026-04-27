import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class AppTitleBar extends StatefulWidget {
  const AppTitleBar({super.key});

  @override
  State<AppTitleBar> createState() => _AppTitleBarState();
}

class _AppTitleBarState extends State<AppTitleBar> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();

    if (isPreventClose) {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  GhostButton.icon(
                    icon: LucideIcons.arrowLeft,
                    semanticLabel: "返回",
                    size: 24,
                    borderRadius: 4,
                    tooltip: '',
                    overlayColor: cs.primary.withAlpha(14),
                    onPressed: () {
                      if (appRouter.canPop()) {
                        appRouter.pop();
                      }
                      return;
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 138, height: 36, child: WindowCaption()),
        ],
      ),
    );
  }
}
