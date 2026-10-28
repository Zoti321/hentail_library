import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 元数据编辑壳：compact 全屏分栏；较宽视口为居中卡片（Widgetbook / Dialog）。
enum Md3eMetadataEditPresentation {
  /// 随窗口宽度在全屏与卡片间切换（Widgetbook、路由页）。
  embedded,

  /// 始终使用 [Dialog] 卡片（较宽视口从详情打开编辑）。
  modal,
}

class Md3eMetadataEditSurface extends StatelessWidget {
  const Md3eMetadataEditSurface({
    super.key,
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onSave,
    this.maxWidth = Md3eMetadataEditFormMetrics.comicMaxWidth,
    this.presentation = Md3eMetadataEditPresentation.embedded,
    this.saving = false,
    this.saveEnabled = true,
    this.onBack,
  });

  final String title;
  final Widget body;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final double maxWidth;
  final Md3eMetadataEditPresentation presentation;
  final bool saving;
  final bool saveEnabled;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final bool useFullPage = presentation == Md3eMetadataEditPresentation.embedded &&
        sizeClass.isCompact;

    if (presentation == Md3eMetadataEditPresentation.modal) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: Md3eMetadataEditFormMetrics.contentHorizontalPadding(sizeClass),
          vertical: M3ETheme.of(context).spacing.lg,
        ),
        child: _DialogCard(
          maxWidth: maxWidth,
          title: title,
          body: body,
          onCancel: onCancel,
          onSave: onSave,
          saving: saving,
          saveEnabled: saveEnabled,
        ),
      );
    }

    if (useFullPage) {
      return _FullPageShell(
        title: title,
        body: body,
        onCancel: onCancel,
        onSave: onSave,
        saving: saving,
        saveEnabled: saveEnabled,
        onBack: onBack ?? onCancel,
      );
    }

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(M3ETheme.of(context).colorScheme),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(
            Md3eMetadataEditFormMetrics.contentHorizontalPadding(sizeClass),
          ),
          child: _DialogCard(
            maxWidth: maxWidth,
            title: title,
            body: body,
            onCancel: onCancel,
            onSave: onSave,
            saving: saving,
            saveEnabled: saveEnabled,
          ),
        ),
      ),
    );
  }
}

class _FullPageShell extends StatelessWidget {
  const _FullPageShell({
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.saveEnabled,
    required this.onBack,
  });

  final String title;
  final Widget body;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final bool saveEnabled;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double horizontal =
        Md3eMetadataEditFormMetrics.contentHorizontalPadding(sizeClass);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal - spacing.xs, 0, horizontal, 0),
              child: Row(
                children: <Widget>[
                  M3EIconButton(
                    onPressed: onBack,
                    icon: const Icon(Symbols.arrow_back),
                    variant: M3EIconButtonVariant.standard,
                    size: M3EIconButtonSize.sm,
                    tooltip: context.l10n.shellBack,
                    semanticLabel: context.l10n.shellBack,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.typeScale.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, spacing.md, horizontal, spacing.lg),
                child: body,
              ),
            ),
            const Divider(height: 1),
            _ActionBar(
              onCancel: onCancel,
              onSave: onSave,
              saving: saving,
              saveEnabled: saveEnabled,
              padding: EdgeInsets.fromLTRB(horizontal, spacing.md, horizontal, spacing.md),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.maxWidth,
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.saveEnabled,
  });

  final double maxWidth;
  final String title;
  final Widget body;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final bool saveEnabled;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final Size size = MediaQuery.sizeOf(context);
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(size.width);
    final double horizontalInset =
        Md3eMetadataEditFormMetrics.contentHorizontalPadding(sizeClass);
    final double width = math.min(maxWidth, size.width - horizontalInset * 2);
    final double maxHeight = size.height * 0.88;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(spacing.md),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.sm),
                child: Text(
                  title,
                  style: theme.typeScale.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
                  child: body,
                ),
              ),
              const Divider(height: 1),
              _ActionBar(
                onCancel: onCancel,
                onSave: onSave,
                saving: saving,
                saveEnabled: saveEnabled,
                padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, spacing.md),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.saveEnabled,
    required this.padding,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final bool saveEnabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          M3EButton(
            onPressed: saving ? null : onCancel,
            style: M3EButtonStyle.text,
            label: Text(l10n.commonCancel),
          ),
          SizedBox(width: spacing.sm),
          M3EButton(
            onPressed: saving || !saveEnabled ? null : onSave,
            style: M3EButtonStyle.filled,
            label: saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: M3ETheme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
