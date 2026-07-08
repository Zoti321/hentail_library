import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

class HentaiDialog extends StatelessWidget {
  const HentaiDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.width = 420,
    this.cardSurfaceKey,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final double width;

  final Key? cardSurfaceKey;

  static const double _dialogInsetPadding = 24;
  static const double _compactActionsBreakpoint = 360;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double effectiveWidth = math.min(
      width,
      viewportWidth - _dialogInsetPadding * 2,
    );
    final double maxDialogHeight = MediaQuery.sizeOf(context).height - 48;
    // 三层阴影：环境光（与页面分离）+ 主抬升 + 贴边接触阴影，浅色下尤其增强层次感
    final ambient = isDark
        ? Colors.black.withAlpha(52)
        : Colors.black.withAlpha(14);
    final contact = isDark
        ? Colors.black.withAlpha(72)
        : Colors.black.withAlpha(22);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(_dialogInsetPadding),
      child: ClipRRect(
        key: cardSurfaceKey,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: effectiveWidth,
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          decoration: BoxDecoration(
            color: cs.hentai.cardHover,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.hentai.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: ambient,
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: cs.hentai.cardShadowHover,
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: cs.hentai.cardShadow,
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: contact,
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.hentai.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: content,
                ),
              ),
              _HentaiDialogActionsBar(actions: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _HentaiDialogActionsBar extends StatelessWidget {
  const _HentaiDialogActionsBar({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compactActions =
            constraints.maxWidth < HentaiDialog._compactActionsBreakpoint;
        final double horizontalPadding = compactActions ? 12 : 16;
        final double actionSpacing = compactActions ? 4 : 8;
        final ThemeData theme = Theme.of(context);
        final ThemeData actionTheme = compactActions
            ? theme.copyWith(
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              )
            : theme;

        return Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            14,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.hentai.borderSubtle,
                width: 1,
              ),
            ),
          ),
          child: Theme(
            data: actionTheme,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: actionSpacing,
              runSpacing: actionSpacing,
              children: _normalizeDialogActions(actions),
            ),
          ),
        );
      },
    );
  }
}

List<Widget> _normalizeDialogActions(List<Widget> actions) {
  return actions
      .where(
        (Widget action) =>
            !(action is SizedBox &&
                action.child == null &&
                action.width != null),
      )
      .toList(growable: false);
}
