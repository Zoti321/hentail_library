import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// Shared dialog / adaptive-form footer: end-aligned [Wrap], fixed spacing,
/// and unified 4px button corners (independent of viewport breakpoint).
class DialogActionsBar extends StatelessWidget {
  const DialogActionsBar({
    super.key,
    required this.actions,
    this.showDivider = true,
    this.padding,
  });

  final List<Widget> actions;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  static const double actionSpacing = 8;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.tokens.radius.xs),
    );
    final ThemeData actionTheme = theme.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: buttonShape),
      ),
    );
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 14);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                top: BorderSide(
                  color: theme.colorScheme.hentai.borderSubtle,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Theme(
        data: actionTheme,
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: actionSpacing,
          runSpacing: actionSpacing,
          children: normalizeDialogActions(actions),
        ),
      ),
    );
  }
}

/// Drops spacer-only [SizedBox]s so [Wrap] owns horizontal gaps.
@visibleForTesting
List<Widget> normalizeDialogActions(List<Widget> actions) {
  return actions
      .where(
        (Widget action) =>
            !(action is SizedBox &&
                action.child == null &&
                action.width != null),
      )
      .toList(growable: false);
}
