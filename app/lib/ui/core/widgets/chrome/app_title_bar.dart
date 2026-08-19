import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class AppTitleBar extends StatefulWidget {
  const AppTitleBar({super.key, this.onOpenSearch});

  final VoidCallback? onOpenSearch;

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
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.hentai.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.onOpenSearch != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GhostButton.icon(
                icon: LucideIcons.search,
                tooltip: '',
                semanticLabel: context.l10n.globalSearchSemantic,
                iconSize: 16,
                size: 28,
                borderRadius: 6,
                foregroundColor: cs.hentai.iconDefault,
                hoverColor: Theme.of(context).hoverColor,
                overlayColor: Theme.of(context).hoverColor,
                delayTooltipThreeSeconds: false,
                onPressed: widget.onOpenSearch,
              ),
            ),
          const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
          const SizedBox(width: 138, height: 36, child: WindowCaption()),
        ],
      ),
    );
  }
}
