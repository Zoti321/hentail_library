import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/value_objects/form/library_form.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/disable_all_format_groups_confirm_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/dialog_side_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

const double _kLibraryFormDialogWidth = 640;
const double _kLibraryFormDialogRadius = 4;
const double _kLibraryFormShellChromeReserve = 120;
const double _kLibraryFormBodyMinHeight = 280;
const Duration _kLibraryFormTabTransitionDuration = Duration(milliseconds: 180);

enum LibraryFormMode { createLocal, createRemote, edit }

enum _LibraryFormTab { general, webDav, scanner }

/// 打开 Library 创建/编辑表面（medium/expanded dialog，compact 全页）。
Future<void> showLibraryFormDialog({
  required BuildContext context,
  required LibraryFormMode mode,
  LocalLibrary? library,
}) {
  assert(
    mode != LibraryFormMode.edit || library != null,
    'library is required for LibraryFormMode.edit',
  );
  return showAdaptiveFormSurfaceWidget<void>(
    context: context,
    surface: LibraryFormDialog(mode: mode, library: library),
  );
}

class LibraryFormDialog extends ConsumerStatefulWidget {
  const LibraryFormDialog({super.key, required this.mode, this.library});

  final LibraryFormMode mode;
  final LocalLibrary? library;

  @override
  ConsumerState<LibraryFormDialog> createState() => _LibraryFormDialogState();
}

class _LibraryFormDialogState extends ConsumerState<LibraryFormDialog> {
  late LibraryForm _form;
  LibraryFormValidation? _validation;
  late List<_LibraryFormTab> _tabs;
  _LibraryFormTab _selectedTab = _LibraryFormTab.general;
  int _previousTabIndex = 0;
  bool _saving = false;
  int _nameFieldRevision = 0;
  int _rootFieldRevision = 0;

  bool get _isCreate => widget.mode != LibraryFormMode.edit;
  bool get _isRemote => _form.isRemote;

  List<FormatGroup> get _selectableFormatGroups {
    if (_isRemote) {
      return FormatGroup.all
          .where((FormatGroup g) => g != FormatGroup.folder)
          .toList(growable: false);
    }
    return FormatGroup.all;
  }

  @override
  void initState() {
    super.initState();
    _form = switch (widget.mode) {
      LibraryFormMode.createLocal => LibraryForm.createLocal(),
      LibraryFormMode.createRemote => LibraryForm.createRemote(),
      LibraryFormMode.edit => LibraryForm.fromLibrary(widget.library!),
    };
    _tabs = _isRemote
        ? const <_LibraryFormTab>[
            _LibraryFormTab.general,
            _LibraryFormTab.webDav,
            _LibraryFormTab.scanner,
          ]
        : const <_LibraryFormTab>[
            _LibraryFormTab.general,
            _LibraryFormTab.scanner,
          ];
  }

  String _title(AppLocalizations l10n) {
    return switch (widget.mode) {
      LibraryFormMode.createLocal => l10n.dialogCreateLocalLibraryTitle,
      LibraryFormMode.createRemote => l10n.dialogCreateRemoteLibraryTitle,
      LibraryFormMode.edit => l10n.dialogEditLibraryTitle,
    };
  }

  String _tabLabel(AppLocalizations l10n, _LibraryFormTab tab) {
    return switch (tab) {
      _LibraryFormTab.general => l10n.dialogEditLibraryTabGeneral,
      _LibraryFormTab.webDav => l10n.dialogEditLibraryTabWebDav,
      _LibraryFormTab.scanner => l10n.dialogEditLibraryTabScanner,
    };
  }

  IconData _tabIcon(_LibraryFormTab tab) {
    return switch (tab) {
      _LibraryFormTab.general => LucideIcons.textAlignCenter,
      _LibraryFormTab.webDav => LucideIcons.cloud,
      _LibraryFormTab.scanner => LucideIcons.scanSearch,
    };
  }

  List<DialogSideTabItem> _sideTabs(AppLocalizations l10n) => _tabs
      .map(
        (_LibraryFormTab tab) => DialogSideTabItem(
          label: _tabLabel(l10n, tab),
          icon: _tabIcon(tab),
        ),
      )
      .toList(growable: false);

  List<CapsuleTabItem> _capsuleTabs(AppLocalizations l10n) => _tabs
      .map(
        (_LibraryFormTab tab) => CapsuleTabItem(
          label: _tabLabel(l10n, tab),
          icon: _tabIcon(tab),
        ),
      )
      .toList(growable: false);

  void _selectTab(int index) {
    if (index < 0 || index >= _tabs.length || index == _tabs.indexOf(_selectedTab)) {
      return;
    }
    setState(() {
      _previousTabIndex = _tabs.indexOf(_selectedTab);
      _selectedTab = _tabs[index];
    });
  }

  String _tabChildKey(_LibraryFormTab tab) {
    return switch (tab) {
      _LibraryFormTab.general => 'general',
      _LibraryFormTab.webDav => 'webdav',
      _LibraryFormTab.scanner => 'scanner',
    };
  }

  Widget _buildTabTransition(Widget child, Animation<double> animation) {
    final int selectedIndex = _tabs.indexOf(_selectedTab);
    final bool slideForward = selectedIndex > _previousTabIndex;
    final double direction = slideForward ? 1 : -1;
    final bool isIncoming =
        child.key == ValueKey<String>(_tabChildKey(_selectedTab));
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final Animation<Offset> offsetAnimation = isIncoming
        ? Tween<Offset>(
            begin: Offset(0.08 * direction, 0),
            end: Offset.zero,
          ).animate(curved)
        : Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-0.08 * direction, 0),
          ).animate(curved);

    return ClipRect(
      child: SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: isIncoming ? animation : ReverseAnimation(animation),
          child: child,
        ),
      ),
    );
  }

  _LibraryFormTab _tabForValidation(LibraryFormValidation validation) {
    if (validation.nameError != null) {
      return _LibraryFormTab.general;
    }
    if (validation.rootError != null) {
      return _isRemote ? _LibraryFormTab.webDav : _LibraryFormTab.general;
    }
    if (validation.passwordError != null) {
      return _LibraryFormTab.webDav;
    }
    return _LibraryFormTab.general;
  }

  Future<bool> _confirmRootChangeIfNeeded() async {
    final LocalLibrary? original = widget.library;
    if (original == null) {
      return true;
    }
    if (_form.rootPath.trim() == original.rootPath.trim()) {
      return true;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            final l10n = dialogContext.l10n;
            final ColorScheme cs = Theme.of(dialogContext).colorScheme;
            return HentaiDialog(
              title: l10n.formLibraryRootChangeConfirmTitle,
              content: Text(
                l10n.formLibraryRootChangeConfirmBody,
                style: TextStyle(fontSize: 14, color: cs.hentai.textSecondary),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        ) ??
        false;
    return confirmed;
  }

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    final LibraryFormValidation validation = _form.validate(isCreate: _isCreate);
    if (!validation.isValid) {
      setState(() {
        _validation = validation;
        _previousTabIndex = _tabs.indexOf(_selectedTab);
        _selectedTab = _tabForValidation(validation);
      });
      return;
    }

    if (requiresDisableAllFormatGroupsConfirm(_form.enabledFormatGroups)) {
      final bool confirmed =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) =>
                const DisableAllFormatGroupsConfirmDialog(),
          ) ??
          false;
      if (!confirmed || !mounted) {
        return;
      }
    }

    if (!await _confirmRootChangeIfNeeded() || !mounted) {
      return;
    }

    setState(() {
      _validation = null;
      _saving = true;
    });
    try {
      final LibraryFormApplyResult result;
      if (_isCreate) {
        result = await _form.create(ref.read(libraryRepoProvider));
      } else {
        result = await _form.applyTo(
          ref.read(libraryRepoProvider),
          widget.library!,
        );
      }
      if (!mounted) {
        return;
      }
      switch (result) {
        case LibraryFormApplyInvalid(
          :final LibraryFormValidation validation,
        ):
          setState(() {
            _validation = validation;
            _previousTabIndex = _tabs.indexOf(_selectedTab);
            _selectedTab = _tabForValidation(validation);
          });
        case LibraryFormApplySucceeded():
          await ref.read(currentLibraryProvider.notifier).refresh();
          ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
          if (!mounted) {
            return;
          }
          final String toast = switch (widget.mode) {
            LibraryFormMode.createLocal => context.l10n.pathsAddedOneToast,
            LibraryFormMode.createRemote => context.l10n.remoteLibraryAddedToast,
            LibraryFormMode.edit => context.l10n.commonSavedToast,
          };
          showSuccessToast(context, toast);
          Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        showCustomToast(
          context,
          message: context.l10n.commonSaveFailedToast,
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _setFormatGroup(FormatGroup group, bool enabled) {
    final Set<FormatGroup> next = _form.enabledFormatGroups.toSet();
    if (enabled) {
      next.add(group);
    } else {
      next.remove(group);
    }
    setState(() {
      _form = _form.copyWith(
        enabledFormatGroups: FormatGroup.all
            .where(next.contains)
            .toList(growable: false),
      );
    });
  }

  Future<void> _browseLocalRoot() async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null || directoryPath.isEmpty || !mounted) {
      return;
    }
    setState(() {
      final bool nameWasEmpty = _form.name.trim().isEmpty;
      _form = _form.copyWith(rootPath: directoryPath);
      _rootFieldRevision++;
      if (nameWasEmpty) {
        _form = _form.copyWith(name: p.basename(directoryPath));
        _nameFieldRevision++;
      }
      if (_validation?.rootError != null || _validation?.nameError != null) {
        _validation = null;
      }
    });
  }

  Widget _buildTabPane(AppThemeTokens tokens) {
    return AnimatedSwitcher(
      duration: _kLibraryFormTabTransitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: _buildTabTransition,
      child: switch (_selectedTab) {
        _LibraryFormTab.general => _LibraryFormGeneralTab(
          key: const ValueKey<String>('general'),
          name: _form.name,
          nameFieldRevision: _nameFieldRevision,
          nameError: _validation?.nameError,
          rootPath: _isRemote ? null : _form.rootPath,
          rootFieldRevision: _rootFieldRevision,
          rootError: _isRemote ? null : _validation?.rootError,
          enabled: !_saving,
          onNameChanged: (String value) {
            setState(() {
              _form = _form.copyWith(name: value);
              if (_validation?.nameError != null) {
                _validation = null;
              }
            });
          },
          onRootChanged: _isRemote
              ? null
              : (String value) {
                  setState(() {
                    _form = _form.copyWith(rootPath: value);
                    if (_validation?.rootError != null) {
                      _validation = null;
                    }
                  });
                },
          onBrowseRoot: _isRemote ? null : _browseLocalRoot,
        ),
        _LibraryFormTab.webDav => _LibraryFormWebDavTab(
          key: const ValueKey<String>('webdav'),
          rootPath: _form.rootPath,
          rootFieldRevision: _rootFieldRevision,
          username: _form.username,
          password: _form.password,
          allowHttp: _form.allowHttp,
          isEdit: !_isCreate,
          rootError: _validation?.rootError,
          passwordError: _validation?.passwordError,
          enabled: !_saving,
          onRootChanged: (String value) {
            setState(() {
              _form = _form.copyWith(rootPath: value);
              if (_validation != null) {
                _validation = null;
              }
            });
          },
          onUsernameChanged: (String value) {
            setState(() => _form = _form.copyWith(username: value));
          },
          onPasswordChanged: (String value) {
            setState(() {
              _form = _form.copyWith(password: value);
              if (_validation?.passwordError != null) {
                _validation = null;
              }
            });
          },
          onAllowHttpChanged: (bool value) {
            setState(() {
              _form = _form.copyWith(allowHttp: value);
              if (_validation?.rootError != null) {
                _validation = null;
              }
            });
          },
        ),
        _LibraryFormTab.scanner => _LibraryFormScannerTab(
          key: const ValueKey<String>('scanner'),
          scanOnStartup: _form.scanOnStartup,
          scanInterval: _form.scanInterval,
          enabledFormatGroups: _form.enabledFormatGroups.toSet(),
          selectableFormatGroups: _selectableFormatGroups,
          enabled: !_saving,
          onScanOnStartupChanged: (bool value) {
            setState(() => _form = _form.copyWith(scanOnStartup: value));
          },
          onScanIntervalChanged: (ScanInterval value) {
            setState(() => _form = _form.copyWith(scanInterval: value));
          },
          onFormatGroupChanged: _setFormatGroup,
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final int selectedTabIndex = _tabs.indexOf(_selectedTab);
    final bool compact = AppLayoutBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    final Widget body;
    if (compact) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.lg,
              0,
              tokens.spacing.lg,
              tokens.spacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CapsuleTabBar(
                items: _capsuleTabs(l10n),
                selectedIndex: selectedTabIndex,
                onSelected: _selectTab,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.lg,
                0,
                tokens.spacing.lg,
                tokens.spacing.xs,
              ),
              child: _buildTabPane(tokens),
            ),
          ),
        ],
      );
    } else {
      body = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: _kLibraryFormBodyMinHeight,
          maxHeight: math.max(
            _kLibraryFormBodyMinHeight,
            MediaQuery.sizeOf(context).height * 0.88 -
                _kLibraryFormShellChromeReserve,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DialogSideTabBar(
              items: _sideTabs(l10n),
              selectedIndex: selectedTabIndex,
              showDivider: false,
              onSelected: _selectTab,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.lg,
                  0,
                  18,
                  tokens.spacing.xs,
                ),
                child: _buildTabPane(tokens),
              ),
            ),
          ],
        ),
      );
    }

    return AdaptiveFormSurface(
      title: _title(l10n),
      maxDialogWidth: _kLibraryFormDialogWidth,
      borderRadius: _kLibraryFormDialogRadius,
      scrollableBody: false,
      bodyPadding: EdgeInsets.zero,
      backgroundColor: cs.surface,
      showFooterDivider: false,
      fitContentHeight: true,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      body: body,
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : Text(_isCreate ? l10n.commonAdd : l10n.commonSaveChanges),
        ),
      ],
    );
  }
}

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
                color: cs.hentai.textSecondary,
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
