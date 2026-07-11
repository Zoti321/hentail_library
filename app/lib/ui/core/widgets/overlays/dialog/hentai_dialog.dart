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
    this.borderRadius = 8,
    this.scrollableContent = true,
    this.contentPadding = const EdgeInsets.fromLTRB(18, 0, 18, 16),
    this.backgroundColor,
    this.showFooterDivider = true,
    this.fitContentHeight = false,
    this.actionsPadding,
    this.cardSurfaceKey,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final double width;
  final double borderRadius;

  /// When false, [content] manages its own scroll/layout (e.g. side tabs + pane).
  final bool scrollableContent;

  /// Padding around [content]. Use [EdgeInsets.zero] when body children manage insets.
  final EdgeInsetsGeometry contentPadding;

  /// Dialog surface color. Defaults to [ColorScheme.hentai.cardHover].
  final Color? backgroundColor;

  /// Top border above the action bar.
  final bool showFooterDivider;

  /// When true, body height follows content between [minContentHeight] and max viewport cap.
  final bool fitContentHeight;

  /// Optional padding for the action bar. Defaults to 12 top / 14 bottom.
  final EdgeInsetsGeometry? actionsPadding;

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
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: effectiveWidth,
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          decoration: BoxDecoration(
            color: backgroundColor ?? cs.hentai.cardHover,
            borderRadius: BorderRadius.circular(borderRadius),
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
              _buildBody(context),
              _HentaiDialogActionsBar(
                actions: actions,
                showDivider: showFooterDivider,
                padding: actionsPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final Widget paddedContent = scrollableContent
        ? SingleChildScrollView(
            padding: contentPadding,
            child: content,
          )
        : Padding(
            padding: contentPadding,
            child: content,
          );

    if (!fitContentHeight) {
      return Flexible(child: paddedContent);
    }

    final double maxBodyHeight = math.max(
      0,
      MediaQuery.sizeOf(context).height - 48 - _fitContentChromeReserve,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxBodyHeight),
      child: paddedContent,
    );
  }

  /// Title + footer approximate height for [fitContentHeight] max body calculation.
  static const double _fitContentChromeReserve = 120;
}

class _HentaiDialogActionsBar extends StatelessWidget {
  const _HentaiDialogActionsBar({
    required this.actions,
    required this.showDivider,
    this.padding,
  });

  final List<Widget> actions;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

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

        final EdgeInsetsGeometry effectivePadding =
            padding ??
            EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              14,
            );

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
