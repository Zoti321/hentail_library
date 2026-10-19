part of 'library_form_dialog.dart';

class _LibraryFormGeneralTab extends StatelessWidget {
  const _LibraryFormGeneralTab({
    super.key,
    required this.name,
    required this.nameFieldRevision,
    required this.nameError,
    required this.rootPath,
    required this.rootFieldRevision,
    required this.rootError,
    required this.enabled,
    required this.onNameChanged,
    required this.onRootChanged,
    required this.onBrowseRoot,
  });

  final String name;
  final int nameFieldRevision;
  final String? nameError;
  final String? rootPath;
  final int rootFieldRevision;
  final String? rootError;
  final bool enabled;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String>? onRootChanged;
  final VoidCallback? onBrowseRoot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        FluentTextField(
          key: ValueKey<String>('library-name-$nameFieldRevision'),
          labelText: l10n.formLibraryNameLabel,
          initialValue: name,
          errorText: nameError,
          enabled: enabled,
          onChanged: onNameChanged,
        ),
        if (rootPath != null && onRootChanged != null && onBrowseRoot != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FormLabel(l10n.formLibraryRootLabel),
              SizedBox(height: tokens.spacing.sm - 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: FluentTextField(
                      key: ValueKey<String>('library-root-$rootFieldRevision'),
                      initialValue: rootPath,
                      errorText: rootError,
                      enabled: enabled,
                      onChanged: onRootChanged!,
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: OutlinedButton(
                      onPressed: enabled ? onBrowseRoot : null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radius.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      child: Text(l10n.formLibraryRootBrowse),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _LibraryFormWebDavTab extends StatelessWidget {
  const _LibraryFormWebDavTab({
    super.key,
    required this.rootPath,
    required this.rootFieldRevision,
    required this.username,
    required this.password,
    required this.allowHttp,
    required this.isEdit,
    required this.rootError,
    required this.passwordError,
    required this.enabled,
    required this.onRootChanged,
    required this.onUsernameChanged,
    required this.onPasswordChanged,
    required this.onAllowHttpChanged,
  });

  final String rootPath;
  final int rootFieldRevision;
  final String username;
  final String password;
  final bool allowHttp;
  final bool isEdit;
  final String? rootError;
  final String? passwordError;
  final bool enabled;
  final ValueChanged<String> onRootChanged;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<bool> onAllowHttpChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        FluentTextField(
          key: ValueKey<String>('webdav-root-$rootFieldRevision'),
          labelText: l10n.remoteLibraryUrlLabel,
          hintText: l10n.remoteLibraryUrlHint,
          initialValue: rootPath,
          errorText: rootError,
          enabled: enabled,
          keyboardType: TextInputType.url,
          onChanged: onRootChanged,
        ),
        FluentTextField(
          labelText: l10n.remoteLibraryUsernameLabel,
          initialValue: username,
          enabled: enabled,
          onChanged: onUsernameChanged,
        ),
        FluentTextField(
          labelText: isEdit
              ? l10n.remoteLibraryPasswordEditLabel
              : l10n.remoteLibraryPasswordLabel,
          hintText: isEdit ? l10n.remoteLibraryPasswordKeepHint : null,
          initialValue: password,
          obscureText: true,
          errorText: passwordError,
          enabled: enabled,
          onChanged: onPasswordChanged,
        ),
        FluentToggleField(
          labelText: l10n.remoteLibraryAllowHttpLabel,
          value: allowHttp,
          enabled: enabled,
          checkedLabel: l10n.remoteLibraryAllowHttpOn,
          uncheckedLabel: l10n.remoteLibraryAllowHttpOff,
          onChanged: onAllowHttpChanged,
        ),
      ],
    );
  }
}

class _LibraryFormScannerTab extends StatelessWidget {
  const _LibraryFormScannerTab({
    super.key,
    required this.scanOnStartup,
    required this.scanInterval,
    required this.enabledFormatGroups,
    required this.selectableFormatGroups,
    required this.enabled,
    required this.onScanOnStartupChanged,
    required this.onScanIntervalChanged,
    required this.onFormatGroupChanged,
  });

  final bool scanOnStartup;
  final ScanInterval scanInterval;
  final Set<FormatGroup> enabledFormatGroups;
  final List<FormatGroup> selectableFormatGroups;
  final bool enabled;
  final ValueChanged<bool> onScanOnStartupChanged;
  final ValueChanged<ScanInterval> onScanIntervalChanged;
  final void Function(FormatGroup group, bool enabled) onFormatGroupChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        FluentToggleField(
          labelText: l10n.formLibraryScanOnStartupLabel,
          value: scanOnStartup,
          enabled: enabled,
          checkedLabel: l10n.formLibraryScanOnStartupOn,
          uncheckedLabel: l10n.formLibraryScanOnStartupOff,
          onChanged: onScanOnStartupChanged,
        ),
        FluentSelectField<ScanInterval>(
          labelText: l10n.formLibraryScanIntervalLabel,
          value: scanInterval,
          items: ScanInterval.values,
          itemLabel: l10n.scanIntervalLabel,
          enabled: enabled,
          onChanged: (ScanInterval? value) {
            if (value == null) {
              return;
            }
            onScanIntervalChanged(value);
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FormLabel(l10n.settingsSupportedFormatsGroupTitle),
            SizedBox(height: tokens.spacing.sm),
            Text(
              l10n.settingsSupportedFormatsDescription,
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: context.hentai.textSecondary,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            for (final FormatGroup group in selectableFormatGroups)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: enabledFormatGroups.contains(group),
                title: Text(l10n.formatGroupLabel(group)),
                onChanged: enabled
                    ? (bool? checked) =>
                          onFormatGroupChanged(group, checked ?? false)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
