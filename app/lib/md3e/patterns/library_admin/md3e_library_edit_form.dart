import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_metrics.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_field_label_row.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_scan_interval_dropdown.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/shared/domain/library/resource_format_category.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum _Md3eLibraryEditTab { general, webDav, scanner }

/// Library 创建/编辑表单（字段对齐生产 [LibraryFormDialog]）。
class Md3eLibraryEditForm extends StatefulWidget {
  const Md3eLibraryEditForm({
    super.key,
    required this.form,
    required this.isCreate,
    required this.onFormChanged,
    this.validation,
    this.enabled = true,
    this.onBrowseRoot,
  });

  final LibraryForm form;
  final bool isCreate;
  final ValueChanged<LibraryForm> onFormChanged;
  final LibraryFormValidation? validation;
  final bool enabled;
  final VoidCallback? onBrowseRoot;

  @override
  State<Md3eLibraryEditForm> createState() => _Md3eLibraryEditFormState();
}

class _Md3eLibraryEditFormState extends State<Md3eLibraryEditForm> {
  _Md3eLibraryEditTab _tab = _Md3eLibraryEditTab.general;

  bool get _isRemote => widget.form.isRemote;

  List<_Md3eLibraryEditTab> get _tabs => _isRemote
      ? const <_Md3eLibraryEditTab>[
          _Md3eLibraryEditTab.general,
          _Md3eLibraryEditTab.webDav,
          _Md3eLibraryEditTab.scanner,
        ]
      : const <_Md3eLibraryEditTab>[
          _Md3eLibraryEditTab.general,
          _Md3eLibraryEditTab.scanner,
        ];

  List<ResourceFormatCategory> get _selectableResourceFormatCategories {
    if (_isRemote) {
      return ResourceFormatCategory.all
          .where((ResourceFormatCategory g) => g != ResourceFormatCategory.folder)
          .toList(growable: false);
    }
    return ResourceFormatCategory.all;
  }

  @override
  void didUpdateWidget(covariant Md3eLibraryEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final LibraryFormValidation? validation = widget.validation;
    if (validation != null && validation != oldWidget.validation) {
      setState(() => _tab = _tabForValidation(validation));
    }
  }

  _Md3eLibraryEditTab _tabForValidation(LibraryFormValidation validation) {
    if (validation.nameError != null) {
      return _Md3eLibraryEditTab.general;
    }
    if (validation.rootError != null) {
      return _isRemote ? _Md3eLibraryEditTab.webDav : _Md3eLibraryEditTab.general;
    }
    if (validation.passwordError != null) {
      return _Md3eLibraryEditTab.webDav;
    }
    return _Md3eLibraryEditTab.general;
  }

  void _patch(LibraryForm Function(LibraryForm f) fn) {
    widget.onFormChanged(fn(widget.form));
  }

  void _setResourceFormatCategory(ResourceFormatCategory group, bool enabled) {
    final Set<ResourceFormatCategory> next = widget.form.enabledResourceFormatCategories.toSet();
    if (enabled) {
      next.add(group);
    } else {
      next.remove(group);
    }
    _patch(
      (LibraryForm f) => f.copyWith(
        enabledResourceFormatCategories: ResourceFormatCategory.all
            .where(next.contains)
            .toList(growable: false),
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _tab = _tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double gap = Md3eLibraryEditFormMetrics.sectionGap(sizeClass);
    final LibraryForm form = widget.form;
    final LibraryFormValidation? validation = widget.validation;

    final Widget tabBody = switch (_tab) {
      _Md3eLibraryEditTab.general => _GeneralTab(
        name: form.name,
        nameError: validation?.nameError,
        rootPath: _isRemote ? null : form.rootPath,
        rootError: _isRemote ? null : validation?.rootError,
        enabled: widget.enabled,
        onBrowseRoot: _isRemote
            ? null
            : () {
                widget.onBrowseRoot?.call();
              },
        onNameChanged: (String value) {
          _patch((LibraryForm f) => f.copyWith(name: value));
        },
        onRootChanged: _isRemote
            ? null
            : (String value) {
                _patch((LibraryForm f) => f.copyWith(rootPath: value));
              },
      ),
      _Md3eLibraryEditTab.webDav => _WebDavTab(
        rootPath: form.rootPath,
        username: form.username,
        password: form.password,
        allowHttp: form.allowHttp,
        isEdit: !widget.isCreate,
        rootError: validation?.rootError,
        passwordError: validation?.passwordError,
        enabled: widget.enabled,
        onRootChanged: (String value) {
          _patch((LibraryForm f) => f.copyWith(rootPath: value));
        },
        onUsernameChanged: (String value) {
          _patch((LibraryForm f) => f.copyWith(username: value));
        },
        onPasswordChanged: (String value) {
          _patch((LibraryForm f) => f.copyWith(password: value));
        },
        onAllowHttpChanged: (bool value) {
          _patch((LibraryForm f) => f.copyWith(allowHttp: value));
        },
      ),
      _Md3eLibraryEditTab.scanner => _ScannerTab(
        scanOnStartup: form.scanOnStartup,
        scanInterval: form.scanInterval,
        enabledResourceFormatCategories: form.enabledResourceFormatCategories.toSet(),
        selectableResourceFormatCategories: _selectableResourceFormatCategories,
        enabled: widget.enabled,
        onScanOnStartupChanged: (bool value) {
          _patch((LibraryForm f) => f.copyWith(scanOnStartup: value));
        },
        onScanIntervalChanged: (ScanInterval value) {
          _patch((LibraryForm f) => f.copyWith(scanInterval: value));
        },
        onResourceFormatCategoryChanged: _setResourceFormatCategory,
      ),
    };

    final bool useSideTabs =
        sizeClass.index >= Md3eWindowSizeClass.medium.index;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool boundedHeight = constraints.maxHeight.isFinite;
        final Widget scrollableTabBody = boundedHeight
            ? SingleChildScrollView(child: tabBody)
            : tabBody;

        if (!useSideTabs) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TopTabBar(
                l10n: l10n,
                tabs: _tabs,
                selected: _tab,
                onSelected: _selectTab,
              ),
              SizedBox(height: gap),
              if (boundedHeight)
                Flexible(child: scrollableTabBody)
              else
                tabBody,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: Md3eLibraryEditFormMetrics.sideTabColumnWidth,
              child: _SideTabList(
                l10n: l10n,
                tabs: _tabs,
                selected: _tab,
                onSelected: _selectTab,
              ),
            ),
            SizedBox(width: gap),
            Expanded(child: scrollableTabBody),
          ],
        );
      },
    );
  }
}

class _TopTabBar extends StatelessWidget {
  const _TopTabBar({
    required this.l10n,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final List<_Md3eLibraryEditTab> tabs;
  final _Md3eLibraryEditTab selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Md3eSegmentedCapsuleBar(
      segments: tabs
          .map(
            (_Md3eLibraryEditTab tab) => Md3eSegmentedCapsuleSegment(
              label: _tabLabel(l10n, tab),
            ),
          )
          .toList(growable: false),
      selectedIndex: tabs.indexOf(selected),
      onSelected: onSelected,
    );
  }
}

class _SideTabList extends StatelessWidget {
  const _SideTabList({
    required this.l10n,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final List<_Md3eLibraryEditTab> tabs;
  final _Md3eLibraryEditTab selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tabs.map((_Md3eLibraryEditTab tab) {
        final bool isSelected = tab == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: M3EButton(
            onPressed: () => onSelected(tabs.indexOf(tab)),
            style: isSelected ? M3EButtonStyle.tonal : M3EButtonStyle.text,
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _tabLabel(l10n, tab),
                style: theme.typeScale.labelLarge.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

String _tabLabel(AppLocalizations l10n, _Md3eLibraryEditTab tab) {
  return switch (tab) {
    _Md3eLibraryEditTab.general => l10n.dialogEditLibraryTabGeneral,
    _Md3eLibraryEditTab.webDav => l10n.dialogEditLibraryTabWebDav,
    _Md3eLibraryEditTab.scanner => l10n.dialogEditLibraryTabScanner,
  };
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({
    required this.name,
    required this.nameError,
    required this.rootPath,
    required this.rootError,
    required this.enabled,
    required this.onBrowseRoot,
    required this.onNameChanged,
    required this.onRootChanged,
  });

  final String name;
  final String? nameError;
  final String? rootPath;
  final String? rootError;
  final bool enabled;
  final VoidCallback? onBrowseRoot;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String>? onRootChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final bool showRoot = rootPath != null && onRootChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eOutlinedTextField(
          label: l10n.formLibraryNameLabel,
          initialValue: name,
          errorText: nameError,
          enabled: enabled,
          onChanged: onNameChanged,
        ),
        if (showRoot) ...<Widget>[
          SizedBox(height: spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Md3eOutlinedTextField(
                  label: l10n.formLibraryRootLabel,
                  initialValue: rootPath,
                  errorText: rootError,
                  enabled: enabled,
                  onChanged: onRootChanged!,
                ),
              ),
              SizedBox(width: spacing.sm),
              M3EButton(
                onPressed: enabled ? onBrowseRoot : null,
                style: M3EButtonStyle.tonal,
                label: Text(l10n.formLibraryRootBrowse),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WebDavTab extends StatelessWidget {
  const _WebDavTab({
    required this.rootPath,
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
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eOutlinedTextField(
          label: l10n.remoteLibraryUrlLabel,
          hintText: l10n.remoteLibraryUrlHint,
          initialValue: rootPath,
          errorText: rootError,
          enabled: enabled,
          keyboardType: TextInputType.url,
          onChanged: onRootChanged,
        ),
        SizedBox(height: spacing.lg),
        Md3eOutlinedTextField(
          label: l10n.remoteLibraryUsernameLabel,
          initialValue: username,
          enabled: enabled,
          onChanged: onUsernameChanged,
        ),
        SizedBox(height: spacing.lg),
        Md3eOutlinedTextField(
          label: isEdit
              ? l10n.remoteLibraryPasswordEditLabel
              : l10n.remoteLibraryPasswordLabel,
          hintText: isEdit ? l10n.remoteLibraryPasswordKeepHint : null,
          initialValue: password,
          errorText: passwordError,
          enabled: enabled,
          obscureText: true,
          showPasswordToggle: true,
          onChanged: onPasswordChanged,
        ),
        SizedBox(height: spacing.lg),
        Md3eSettingsSwitchTile(
          title: Text(l10n.remoteLibraryAllowHttpLabel),
          value: allowHttp,
          enabled: enabled,
          onChanged: onAllowHttpChanged,
          description: Text(
            allowHttp
                ? l10n.remoteLibraryAllowHttpOn
                : l10n.remoteLibraryAllowHttpOff,
          ),
        ),
      ],
    );
  }
}

class _ScannerTab extends StatelessWidget {
  const _ScannerTab({
    required this.scanOnStartup,
    required this.scanInterval,
    required this.enabledResourceFormatCategories,
    required this.selectableResourceFormatCategories,
    required this.enabled,
    required this.onScanOnStartupChanged,
    required this.onScanIntervalChanged,
    required this.onResourceFormatCategoryChanged,
  });

  final bool scanOnStartup;
  final ScanInterval scanInterval;
  final Set<ResourceFormatCategory> enabledResourceFormatCategories;
  final List<ResourceFormatCategory> selectableResourceFormatCategories;
  final bool enabled;
  final ValueChanged<bool> onScanOnStartupChanged;
  final ValueChanged<ScanInterval> onScanIntervalChanged;
  final void Function(ResourceFormatCategory group, bool enabled) onResourceFormatCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final M3EColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eSettingsSwitchTile(
          title: Text(l10n.formLibraryScanOnStartupLabel),
          value: scanOnStartup,
          enabled: enabled,
          onChanged: onScanOnStartupChanged,
          description: Text(
            scanOnStartup
                ? l10n.formLibraryScanOnStartupOn
                : l10n.formLibraryScanOnStartupOff,
          ),
        ),
        SizedBox(height: spacing.lg),
        Md3eMetadataFieldLabelRow(label: l10n.formLibraryScanIntervalLabel),
        SizedBox(height: spacing.sm),
        Md3eScanIntervalDropdown(
          value: scanInterval,
          enabled: enabled,
          onChanged: onScanIntervalChanged,
        ),
        SizedBox(height: spacing.lg),
        Text(
          l10n.settingsSupportedFormatsGroupTitle,
          style: theme.typeScale.titleSmall.copyWith(
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: spacing.sm),
        Text(
          l10n.settingsSupportedFormatsDescription,
          style: theme.typeScale.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.sm),
        for (final ResourceFormatCategory group in selectableResourceFormatCategories)
          _ResourceFormatCategoryRow(
            label: l10n.resourceFormatCategoryLabel(group),
            selected: enabledResourceFormatCategories.contains(group),
            enabled: enabled,
            onChanged: (bool value) => onResourceFormatCategoryChanged(group, value),
          ),
      ],
    );
  }
}

class _ResourceFormatCategoryRow extends StatelessWidget {
  const _ResourceFormatCategoryRow({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final Md3eLibraryFilterSortRowMetrics metrics =
        Md3eLibraryFilterSortRowMetrics.forViewportWidth(
          MediaQuery.sizeOf(context).width,
        );

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: enabled ? () => onChanged(!selected) : null,
        child: SizedBox(
          height: metrics.rowMinHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              M3ECheckbox(
                value: selected,
                onChanged: enabled ? (_) => onChanged(!selected) : null,
                focusable: false,
                boxSize: metrics.checkboxBoxSize,
                hitSize: metrics.checkboxHitSize,
                targetSize: metrics.checkboxTargetSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.typeScale.bodyLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: metrics.optionLabelFontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
