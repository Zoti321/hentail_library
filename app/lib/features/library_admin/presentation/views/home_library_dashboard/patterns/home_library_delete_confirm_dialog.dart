import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 从 Home「我的漫画库」移除 Library 的确认（勾选闸门；不删 Resource）。
Future<bool> showHomeLibraryDeleteConfirmDialog({
  required BuildContext context,
  required String libraryDisplayName,
}) async {
  final bool? confirmed = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: _HomeLibraryDeleteConfirmDialog(
      libraryDisplayName: libraryDisplayName,
    ),
  );
  return confirmed ?? false;
}

class _HomeLibraryDeleteConfirmDialog extends StatefulWidget {
  const _HomeLibraryDeleteConfirmDialog({required this.libraryDisplayName});

  final String libraryDisplayName;

  @override
  State<_HomeLibraryDeleteConfirmDialog> createState() =>
      _HomeLibraryDeleteConfirmDialogState();
}

class _HomeLibraryDeleteConfirmDialogState
    extends State<_HomeLibraryDeleteConfirmDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;

    return M3EDialog(
      title: l10n.homeLibraryDeleteConfirmTitle(widget.libraryDisplayName),
      content: _HomeLibraryDeleteConfirmBody(
        acknowledged: _acknowledged,
        onAcknowledgementChanged: (bool value) {
          setState(() => _acknowledged = value);
        },
        scheme: scheme,
        spacing: spacing,
        theme: theme,
      ),
      bottomDivider: true,
      actions: <Widget>[
        DialogActionBar(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          cancelLabel: l10n.commonCancel,
          confirmLabel: l10n.sidebarDeleteLibrary,
          destructive: true,
          confirmEnabled: _acknowledged,
        ),
      ],
    );
  }
}

/// Dialog 正文：说明 + 勾选闸门（复选框与说明文案垂直居中）。
class _HomeLibraryDeleteConfirmBody extends StatelessWidget {
  const _HomeLibraryDeleteConfirmBody({
    required this.acknowledged,
    required this.onAcknowledgementChanged,
    required this.scheme,
    required this.spacing,
    required this.theme,
  });

  final bool acknowledged;
  final ValueChanged<bool> onAcknowledgementChanged;
  final M3EColorScheme scheme;
  final M3ESpacing spacing;
  final M3EThemeData theme;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextStyle descriptionStyle = theme.typeScale.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final TextStyle acknowledgementStyle = theme.typeScale.bodyMedium.copyWith(
      color: scheme.onSurface,
    );

    void toggleAcknowledgement() {
      onAcknowledgementChanged(!acknowledged);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.homeLibraryDeleteConfirmBody, style: descriptionStyle),
        SizedBox(height: spacing.md),
        InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: toggleAcknowledgement,
          child: Row(
            children: <Widget>[
              M3ECheckbox(
                value: acknowledged,
                onChanged: (bool? value) {
                  onAcknowledgementChanged(value ?? false);
                },
                focusable: true,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  l10n.homeLibraryDeleteConfirmAcknowledge,
                  style: acknowledgementStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
