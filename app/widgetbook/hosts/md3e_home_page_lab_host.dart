import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_layout.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_edit_page.dart';

import '../lab/navigation/md3e_library_edit_navigation.dart';

import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_management_section.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_delete_confirm_dialog.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_list_order.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/named_metadata/public/ui/metadata_lab_patterns.dart';

import '../preview/md3e_home_page_preview_data.dart';
import 'md3e_history_browse_page_lab_host.dart';
import 'md3e_management_browse_page_lab_host.dart';

/// Lab-only snackbars：预览不接真实 Library sync / metadata refresh。
abstract final class _HomePageLabPreviewCopy {
  static const String scanPreviewSnackBar = 'Lab 预览：未执行 Library sync';
  static const String metadataRefreshPreviewSnackBar =
      'Lab 预览：未执行 Metadata refresh';
}

/// Widgetbook / Lab：在本地维护库列表顺序；生产侧由 notifier + repository 接同样回调形状。
///
/// 未注入 callback 时提供 Lab 默认编排（Library form 导航、mock 扫描/删除）。
class HomePageLabHost extends StatefulWidget {
  const HomePageLabHost({
    super.key,
    this.initialLibraries,
    this.onOpenNavigation,
    this.onLibraryOpen,
    this.onLibraryAction,
    this.onAddLocalLibrary,
    this.onAddRemoteLibrary,
    this.enableReorder = true,
  });

  final List<HomeLibraryDashboardRow>? initialLibraries;
  final VoidCallback? onOpenNavigation;
  final ValueChanged<String>? onLibraryOpen;
  final void Function(String libraryId, HomeLibraryManagementAction action)?
  onLibraryAction;
  final VoidCallback? onAddLocalLibrary;
  final VoidCallback? onAddRemoteLibrary;
  final bool enableReorder;

  @override
  State<HomePageLabHost> createState() => _Md3eHomePageLabHostState();
}

class _Md3eHomePageLabHostState extends State<HomePageLabHost> {
  late List<HomeLibraryDashboardRow> _libraries =
      List<HomeLibraryDashboardRow>.of(
        widget.initialLibraries ?? HomePagePreviewData.sampleLibraries(),
      );

  final Map<String, Timer> _busyResetTimers = <String, Timer>{};

  @override
  void dispose() {
    for (final Timer timer in _busyResetTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePageLabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLibraries != null &&
        widget.initialLibraries != oldWidget.initialLibraries) {
      _libraries = List<HomeLibraryDashboardRow>.of(
        widget.initialLibraries!,
      );
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      _libraries = applyHomeLibraryListReorder(
        _libraries,
        oldIndex,
        newIndex,
      );
    });
  }

  HomeLibraryDashboardRow? _rowFor(String libraryId) {
    for (final HomeLibraryDashboardRow row in _libraries) {
      if (row.libraryId == libraryId) {
        return row;
      }
    }
    return null;
  }

  void _updateRow(HomeLibraryDashboardRow next) {
    final int index = _libraries.indexWhere(
      (HomeLibraryDashboardRow row) => row.libraryId == next.libraryId,
    );
    if (index < 0) {
      return;
    }
    setState(() {
      _libraries = List<HomeLibraryDashboardRow>.of(_libraries)
        ..[index] = next;
    });
  }

  void _scheduleBusyReset(String libraryId) {
    _busyResetTimers[libraryId]?.cancel();
    _busyResetTimers[libraryId] = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      final HomeLibraryDashboardRow? row = _rowFor(libraryId);
      if (row == null) {
        return;
      }
      _updateRow(
        row.copyWith(scanInProgress: false, metadataRefreshInProgress: false),
      );
      _busyResetTimers.remove(libraryId);
    });
  }

  Future<void> _openLibraryEdit(LibraryEditPageIntent intent) async {
    await showLibraryEdit(context: context, intent: intent);
  }

  void _defaultAddLocalLibrary() {
    unawaited(_openLibraryEdit(LibraryEditPageIntent.createLocal));
  }

  void _defaultAddRemoteLibrary() {
    unawaited(_openLibraryEdit(LibraryEditPageIntent.createRemote));
  }

  Future<void> _defaultLibraryAction(
    String libraryId,
    HomeLibraryManagementAction action,
  ) async {
    final HomeLibraryDashboardRow? row = _rowFor(libraryId);
    if (row == null) {
      return;
    }

    switch (action) {
      case HomeLibraryManagementAction.edit:
        final LibraryEditPageIntent intent =
            row.kind == HomeLibraryKind.remote
            ? LibraryEditPageIntent.editRemote
            : LibraryEditPageIntent.editLocal;
        await _openLibraryEdit(intent);
      case HomeLibraryManagementAction.scan:
      case HomeLibraryManagementAction.deepScan:
        _updateRow(row.copyWith(scanInProgress: true));
        _scheduleBusyReset(libraryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                _HomePageLabPreviewCopy.scanPreviewSnackBar,
              ),
            ),
          );
        }
      case HomeLibraryManagementAction.refreshMetadata:
        _updateRow(row.copyWith(metadataRefreshInProgress: true));
        _scheduleBusyReset(libraryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                _HomePageLabPreviewCopy.metadataRefreshPreviewSnackBar,
              ),
            ),
          );
        }
      case HomeLibraryManagementAction.delete:
        final bool confirmed = await showHomeLibraryDeleteConfirmDialog(
          context: context,
          libraryDisplayName: row.displayName,
        );
        if (!confirmed || !mounted) {
          return;
        }
        setState(() {
          _libraries = _libraries
              .where(
                (HomeLibraryDashboardRow item) =>
                    item.libraryId != libraryId,
              )
              .toList(growable: false);
        });
    }
  }

  void _handleLibraryAction(
    String libraryId,
    HomeLibraryManagementAction action,
  ) {
    if (widget.onLibraryAction != null) {
      widget.onLibraryAction!(libraryId, action);
      return;
    }
    unawaited(_defaultLibraryAction(libraryId, action));
  }

  void _openManagement(ManagedNamedFacetKind facet) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              ManagementBrowsePageLabHost(initialFacet: facet),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeLayout(
      aggregateCounts: HomePagePreviewData.sampleAggregateCounts(),
      onOpenNavigation: widget.onOpenNavigation,
      onOpenHistory: () {
        unawaited(
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  HistoryBrowsePageLabHost(clock: DateTime(2026, 6, 15, 14)),
            ),
          ),
        );
      },
      onOpenTrash: () {
        unawaited(
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => Scaffold(
                body: Center(child: Text(context.l10n.navTrash)),
              ),
            ),
          ),
        );
      },
      onOpenAuthors: () => _openManagement(ManagedNamedFacetKind.author),
      onOpenParodies: () => _openManagement(ManagedNamedFacetKind.parody),
      onOpenCharacters: () => _openManagement(ManagedNamedFacetKind.character),
      onOpenTags: () => _openManagement(ManagedNamedFacetKind.tag),
      libraryManagementSection: HomeLibraryManagementSection(
        libraries: _libraries,
        onLibraryOpen: widget.onLibraryOpen,
        onLibraryAction: _handleLibraryAction,
        onAddLocalLibrary:
            widget.onAddLocalLibrary ?? _defaultAddLocalLibrary,
        onAddRemoteLibrary:
            widget.onAddRemoteLibrary ?? _defaultAddRemoteLibrary,
        onLibrariesReorder: widget.enableReorder ? _handleReorder : null,
      ),
    );
  }
}
