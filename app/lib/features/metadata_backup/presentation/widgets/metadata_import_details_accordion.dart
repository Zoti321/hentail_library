import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hentai_library/design-system/design_system.dart';

class MetadataImportDetailsAccordion extends StatelessWidget {
  const MetadataImportDetailsAccordion({
    super.key,
    required this.expanded,
    required this.title,
    required this.onExpandedChanged,
    required this.child,
  });

  final bool expanded;
  final String title;
  final ValueChanged<bool> onExpandedChanged;
  final Widget child;

  static const Duration _duration = Duration(milliseconds: 200);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onExpandedChanged(!expanded),
            hoverColor: theme.hoverColor,
            splashColor: theme.splashColor,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: _duration,
                    curve: _curve,
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _duration,
          curve: _curve,
          alignment: Alignment.topCenter,
          child: expanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
