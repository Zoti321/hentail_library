import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/value_objects/form/library_settings_form.dart';
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
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kEditLibraryDialogWidth = 640;
const double _kEditLibraryDialogRadius = 4;
const double _kEditLibraryShellChromeReserve = 120;
const double _kEditLibraryBodyMinHeight = 280;
const Duration _kEditLibraryTabTransitionDuration = Duration(milliseconds: 180);

enum _EditLibraryTab { general, scanner }

/// 打开 Library 设置编辑表面（medium/expanded dialog，compact 全页）。
Future<void> showEditLibrarySettingsDialog({
  required BuildContext context,
  required LocalLibrary library,
}) {
  return showAdaptiveFormSurfaceWidget<void>(
    context: context,
    surface: EditLibrarySettingsDialog(library: library),
  );
}

class EditLibrarySettingsDialog extends ConsumerStatefulWidget {
  const EditLibrarySettingsDialog({super.key, required this.library});

  final LocalLibrary library;

  @override
  ConsumerState<EditLibrarySettingsDialog> createState() =>
      _EditLibrarySettingsDialogState();
}

class _EditLibrarySettingsDialogState
    extends ConsumerState<EditLibrarySettingsDialog> {
  late LibrarySettingsForm _form;
  LibrarySettingsFormValidation? _validation;
  _EditLibraryTab _selectedTab = _EditLibraryTab.general;
  int _previousTabIndex = 0;
  bool _saving = false;

  List<FormatGroup> get _selectableFormatGroups {
    if (isRemoteLibrary(widget.library)) {
      return FormatGroup.all
          .where((FormatGroup g) => g != FormatGroup.folder)
          .toList(growable: false);
    }
    return FormatGroup.all;
  }

  @override
  void initState() {
    super.initState();
    LibrarySettingsForm form = LibrarySettingsForm.fromLibrary(widget.library);
    if (isRemoteLibrary(widget.library)) {
      form = form.copyWith(
        enabledFormatGroups: form.enabledFormatGroups
            .where((FormatGroup g) => g != FormatGroup.folder)
            .toList(growable: false),
      );
    }
    _form = form;
  }

  List<DialogSideTabItem> _sideTabs(AppLocalizations l10n) =>
      <DialogSideTabItem>[
        DialogSideTabItem(
          label: l10n.dialogEditLibraryTabGeneral,
          icon: LucideIcons.textAlignCenter,
        ),
        DialogSideTabItem(
          label: l10n.dialogEditLibraryTabScanner,
          icon: LucideIcons.scanSearch,
        ),
      ];

  List<CapsuleTabItem> _capsuleTabs(AppLocalizations l10n) => <CapsuleTabItem>[
    CapsuleTabItem(
      label: l10n.dialogEditLibraryTabGeneral,
      icon: LucideIcons.textAlignCenter,
    ),
    CapsuleTabItem(
      label: l10n.dialogEditLibraryTabScanner,
      icon: LucideIcons.scanSearch,
    ),
  ];

  void _selectTab(int index) {
    if (index == _selectedTab.index) {
      return;
    }
    setState(() {
      _previousTabIndex = _selectedTab.index;
      _selectedTab = _EditLibraryTab.values[index];
    });
  }

  String _tabChildKey(_EditLibraryTab tab) {
    return switch (tab) {
      _EditLibraryTab.general => 'general',
      _EditLibraryTab.scanner => 'scanner',
    };
  }

  Widget _buildTabTransition(Widget child, Animation<double> animation) {
    final bool slideForward = _selectedTab.index > _previousTabIndex;
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

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    final LibrarySettingsFormValidation validation = _form.validate();
    if (!validation.isValid) {
      setState(() {
        _validation = validation;
        _previousTabIndex = _selectedTab.index;
        _selectedTab = _EditLibraryTab.general;
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

    setState(() {
      _validation = null;
      _saving = true;
    });
    try {
      final LibrarySettingsApplyResult result = await _form.applyTo(
        ref.read(libraryRepoProvider),
        widget.library,
      );
      if (!mounted) {
        return;
      }
      switch (result) {
        case LibrarySettingsApplyInvalid(
          :final LibrarySettingsFormValidation validation,
        ):
          setState(() {
            _validation = validation;
            _previousTabIndex = _selectedTab.index;
            _selectedTab = _EditLibraryTab.general;
          });
        case LibrarySettingsApplySucceeded():
          await ref.read(currentLibraryProvider.notifier).refresh();
          if (!mounted) {
            return;
          }
          showSuccessToast(context, context.l10n.commonSavedToast);
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

  Widget _buildTabPane(AppThemeTokens tokens) {
    return AnimatedSwitcher(
      duration: _kEditLibraryTabTransitionDuration,
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
        _EditLibraryTab.general => _EditLibraryGeneralTab(
          key: const ValueKey<String>('general'),
          name: _form.name,
          nameError: _validation?.nameError,
          rootPath: widget.library.rootPath,
          enabled: !_saving,
          onNameChanged: (String value) {
            setState(() {
              _form = _form.copyWith(name: value);
              if (_validation?.nameError != null) {
                _validation = const LibrarySettingsFormValidation();
              }
            });
          },
        ),
        _EditLibraryTab.scanner => _EditLibraryScannerTab(
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
    final int selectedTabIndex = _selectedTab.index;
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
          minHeight: _kEditLibraryBodyMinHeight,
          maxHeight: math.max(
            _kEditLibraryBodyMinHeight,
            MediaQuery.sizeOf(context).height * 0.88 -
                _kEditLibraryShellChromeReserve,
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
      title: l10n.dialogEditLibraryTitle,
      maxDialogWidth: _kEditLibraryDialogWidth,
      borderRadius: _kEditLibraryDialogRadius,
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
              : Text(l10n.commonSaveChanges),
        ),
      ],
    );
  }
}

class _EditLibraryGeneralTab extends StatelessWidget {
  const _EditLibraryGeneralTab({
    super.key,
    required this.name,
    required this.nameError,
    required this.rootPath,
    required this.enabled,
    required this.onNameChanged,
  });

  final String name;
  final String? nameError;
  final String rootPath;
  final bool enabled;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        FluentTextField(
          labelText: l10n.formLibraryNameLabel,
          initialValue: name,
          errorText: nameError,
          enabled: enabled,
          onChanged: onNameChanged,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FormLabel(l10n.formLibraryRootLabel),
            SizedBox(height: tokens.spacing.sm - 2),
            SelectableText(
              rootPath,
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                color: cs.hentai.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditLibraryScannerTab extends StatelessWidget {
  const _EditLibraryScannerTab({
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
