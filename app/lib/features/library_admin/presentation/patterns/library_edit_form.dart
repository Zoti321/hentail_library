import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/library_admin/presentation/widgets/library_edit_form_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_filter_sort_metrics.dart';
import 'package:hentai_library/features/library_admin/presentation/widgets/scan_interval_dropdown.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_admin/public/ui/l10n/library_admin_l10n.dart';

enum _LibraryEditTab { general, webDav, scanner }

/// Library 创建/编辑表单（字段对齐生产 [LibraryFormDialog]）。
class LibraryEditForm extends StatefulWidget {
  const LibraryEditForm({
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
  State<LibraryEditForm> createState() => _LibraryEditFormState();
}

class _LibraryEditFormState extends State<LibraryEditForm> {
  _LibraryEditTab _tab = _LibraryEditTab.general;
  bool _detailTransitionReverse = false;

  bool get _isRemote => widget.form.isRemote;

  List<_LibraryEditTab> get _tabs => _isRemote
      ? const <_LibraryEditTab>[
          _LibraryEditTab.general,
          _LibraryEditTab.webDav,
          _LibraryEditTab.scanner,
        ]
      : const <_LibraryEditTab>[
          _LibraryEditTab.general,
          _LibraryEditTab.scanner,
        ];

  List<ResourceFormatCategory> get _selectableResourceFormatCategories {
    if (_isRemote) {
      return ResourceFormatCategory.all
          .where(
            (ResourceFormatCategory g) => g != ResourceFormatCategory.folder,
          )
          .toList(growable: false);
    }
    return ResourceFormatCategory.all;
  }

  @override
  void didUpdateWidget(covariant LibraryEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final LibraryFormValidation? validation = widget.validation;
    if (validation != null && validation != oldWidget.validation) {
      // didUpdateWidget 后必然 build，无需 setState。
      _tab = _tabForValidation(validation);
    }
  }

  _LibraryEditTab _tabForValidation(LibraryFormValidation validation) {
    if (validation.nameError != null) {
      return _LibraryEditTab.general;
    }
    if (validation.rootError != null) {
      return _isRemote ? _LibraryEditTab.webDav : _LibraryEditTab.general;
    }
    if (validation.passwordError != null) {
      return _LibraryEditTab.webDav;
    }
    return _LibraryEditTab.general;
  }

  void _patch(LibraryForm Function(LibraryForm f) fn) {
    // 文本框在 build 期间同步 initialValue 时会回调相同值；忽略无变化的更新，
    // 避免父级在 build 中 setState。
    final LibraryForm next = fn(widget.form);
    if (next == widget.form) {
      return;
    }
    widget.onFormChanged(next);
  }

  void _setResourceFormatCategory(ResourceFormatCategory group, bool enabled) {
    final Set<ResourceFormatCategory> next = widget
        .form
        .enabledResourceFormatCategories
        .toSet();
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
    setState(() {
      final _LibraryEditTab next = _tabs[index];
      _detailTransitionReverse = _tabs.indexOf(next) < _tabs.indexOf(_tab);
      _tab = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double gap = LibraryEditFormMetrics.sectionGap(sizeClass);
    final LibraryForm form = widget.form;
    final LibraryFormValidation? validation = widget.validation;

    final Widget tabBody = switch (_tab) {
      _LibraryEditTab.general => _GeneralTab(
        name: form.name,
        nameError: validation?.nameError,
        rootPath: _isRemote ? null : form.rootPath,
        rootError: _isRemote ? null : validation?.rootError,
        enabled: widget.enabled,
        onBrowseRoot: _isRemote ? null : () => widget.onBrowseRoot?.call(),
        onNameChanged: (String value) =>
            _patch((LibraryForm f) => f.copyWith(name: value)),
        onRootChanged: _isRemote
            ? null
            : (String value) =>
                  _patch((LibraryForm f) => f.copyWith(rootPath: value)),
      ),
      _LibraryEditTab.webDav => _WebDavTab(
        rootPath: form.rootPath,
        username: form.username,
        password: form.password,
        allowHttp: form.allowHttp,
        isEdit: !widget.isCreate,
        rootError: validation?.rootError,
        passwordError: validation?.passwordError,
        enabled: widget.enabled,
        onRootChanged: (String value) =>
            _patch((LibraryForm f) => f.copyWith(rootPath: value)),
        onUsernameChanged: (String value) =>
            _patch((LibraryForm f) => f.copyWith(username: value)),
        onPasswordChanged: (String value) =>
            _patch((LibraryForm f) => f.copyWith(password: value)),
        onAllowHttpChanged: (bool value) =>
            _patch((LibraryForm f) => f.copyWith(allowHttp: value)),
      ),
      _LibraryEditTab.scanner => _ScannerTab(
        scanOnStartup: form.scanOnStartup,
        scanInterval: form.scanInterval,
        enabledResourceFormatCategories: form.enabledResourceFormatCategories
            .toSet(),
        selectableResourceFormatCategories: _selectableResourceFormatCategories,
        enabled: widget.enabled,
        onScanOnStartupChanged: (bool value) =>
            _patch((LibraryForm f) => f.copyWith(scanOnStartup: value)),
        onScanIntervalChanged: (ScanInterval value) =>
            _patch((LibraryForm f) => f.copyWith(scanInterval: value)),
        onResourceFormatCategoryChanged: _setResourceFormatCategory,
      ),
    };

    final bool useSideTabs = sizeClass.index >= WindowSizeClass.medium.index;

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
                Flexible(
                  child: _DetailTransition(
                    tab: _tab,
                    reverse: _detailTransitionReverse,
                    child: scrollableTabBody,
                  ),
                )
              else
                _DetailTransition(
                  tab: _tab,
                  reverse: _detailTransitionReverse,
                  child: tabBody,
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: LibraryEditFormMetrics.sideTabColumnWidth,
              child: _SideTabList(
                l10n: l10n,
                tabs: _tabs,
                selected: _tab,
                onSelected: _selectTab,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _DetailTransition(
                tab: _tab,
                reverse: _detailTransitionReverse,
                child: scrollableTabBody,
              ),
            ),
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
  final List<_LibraryEditTab> tabs;
  final _LibraryEditTab selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedCapsuleBar(
      segments: tabs
          .map(
            (_LibraryEditTab tab) =>
                SegmentedCapsuleSegment(label: _tabLabel(l10n, tab)),
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
  final List<_LibraryEditTab> tabs;
  final _LibraryEditTab selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final _LibraryEditTab tab in tabs)
          ListDetailNavItem(
            key: ValueKey<_LibraryEditTab>(tab),
            label: _tabLabel(l10n, tab),
            selected: tab == selected,
            onTap: () => onSelected(tabs.indexOf(tab)),
          ),
      ],
    );
  }
}

String _tabLabel(AppLocalizations l10n, _LibraryEditTab tab) {
  return switch (tab) {
    _LibraryEditTab.general => l10n.dialogEditLibraryTabGeneral,
    _LibraryEditTab.webDav => l10n.dialogEditLibraryTabWebDav,
    _LibraryEditTab.scanner => l10n.dialogEditLibraryTabScanner,
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
        OutlinedTextField(
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
                child: OutlinedTextField(
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
        OutlinedTextField(
          label: l10n.remoteLibraryUrlLabel,
          hintText: l10n.remoteLibraryUrlHint,
          initialValue: rootPath,
          errorText: rootError,
          enabled: enabled,
          keyboardType: TextInputType.url,
          onChanged: onRootChanged,
        ),
        SizedBox(height: spacing.lg),
        OutlinedTextField(
          label: l10n.remoteLibraryUsernameLabel,
          initialValue: username,
          enabled: enabled,
          onChanged: onUsernameChanged,
        ),
        SizedBox(height: spacing.lg),
        OutlinedTextField(
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
        SettingsSwitchTile(
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
  final void Function(ResourceFormatCategory group, bool enabled)
  onResourceFormatCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final M3EColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSwitchTile(
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
        MetadataFieldLabelRow(label: l10n.formLibraryScanIntervalLabel),
        SizedBox(height: spacing.sm),
        ScanIntervalDropdown(
          value: scanInterval,
          enabled: enabled,
          onChanged: onScanIntervalChanged,
        ),
        SizedBox(height: spacing.lg),
        Text(
          l10n.settingsSupportedFormatsGroupTitle,
          style: theme.typeScale.titleSmall.copyWith(color: scheme.onSurface),
        ),
        SizedBox(height: spacing.sm),
        Text(
          l10n.settingsSupportedFormatsDescription,
          style: theme.typeScale.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.sm),
        for (final ResourceFormatCategory group
            in selectableResourceFormatCategories)
          _ResourceFormatCategoryRow(
            label: l10n.resourceFormatCategoryLabel(group),
            selected: enabledResourceFormatCategories.contains(group),
            enabled: enabled,
            onChanged: (bool value) =>
                onResourceFormatCategoryChanged(group, value),
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
    final LibraryFilterSortRowMetrics metrics =
        LibraryFilterSortRowMetrics.forViewportWidth(
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

class _DetailTransition extends StatelessWidget {
  const _DetailTransition({
    required this.tab,
    required this.reverse,
    required this.child,
  });

  final _LibraryEditTab tab;
  final bool reverse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListDetailDetailTransition(
      switchKey: tab,
      reverse: reverse,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LibraryEditFormMetrics.detailContentHorizontalInset,
        ),
        child: child,
      ),
    );
  }
}
