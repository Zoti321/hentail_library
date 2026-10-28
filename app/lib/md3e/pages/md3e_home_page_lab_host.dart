import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_home_page.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/md3e/patterns/library_admin/md3e_library_edit_navigation.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_delete_confirm_dialog.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_list_order.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_page_preview_data.dart';

/// Widgetbook / Lab：在本地维护库列表顺序；生产侧由 notifier + repository 接同样回调形状。
///
/// 未注入 callback 时提供 Lab 默认编排（Library form 导航、mock 扫描/删除）。
class Md3eHomePageLabHost extends StatefulWidget {
  const Md3eHomePageLabHost({
    super.key,
    this.initialLibraries,
    this.onOpenNavigation,
    this.onLibraryOpen,
    this.onLibraryAction,
    this.onAddLocalLibrary,
    this.onAddRemoteLibrary,
    this.enableReorder = true,
  });

  final List<Md3eHomeLibraryDashboardRow>? initialLibraries;
  final VoidCallback? onOpenNavigation;
  final ValueChanged<String>? onLibraryOpen;
  final void Function(String libraryId, Md3eHomeLibraryManagementAction action)?
      onLibraryAction;
  final VoidCallback? onAddLocalLibrary;
  final VoidCallback? onAddRemoteLibrary;
  final bool enableReorder;

  @override
  State<Md3eHomePageLabHost> createState() => _Md3eHomePageLabHostState();
}

class _Md3eHomePageLabHostState extends State<Md3eHomePageLabHost> {
  late List<Md3eHomeLibraryDashboardRow> _libraries =
      List<Md3eHomeLibraryDashboardRow>.of(
        widget.initialLibraries ?? Md3eHomePagePreviewData.sampleLibraries(),
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
  void didUpdateWidget(covariant Md3eHomePageLabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLibraries != null &&
        widget.initialLibraries != oldWidget.initialLibraries) {
      _libraries = List<Md3eHomeLibraryDashboardRow>.of(widget.initialLibraries!);
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      _libraries = applyMd3eHomeLibraryListReorder(
        _libraries,
        oldIndex,
        newIndex,
      );
    });
  }

  Md3eHomeLibraryDashboardRow? _rowFor(String libraryId) {
    for (final Md3eHomeLibraryDashboardRow row in _libraries) {
      if (row.libraryId == libraryId) {
        return row;
      }
    }
    return null;
  }

  void _updateRow(Md3eHomeLibraryDashboardRow next) {
    final int index = _libraries.indexWhere(
      (Md3eHomeLibraryDashboardRow row) => row.libraryId == next.libraryId,
    );
    if (index < 0) {
      return;
    }
    setState(() {
      _libraries = List<Md3eHomeLibraryDashboardRow>.of(_libraries)
        ..[index] = next;
    });
  }

  void _scheduleBusyReset(String libraryId) {
    _busyResetTimers[libraryId]?.cancel();
    _busyResetTimers[libraryId] = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      final Md3eHomeLibraryDashboardRow? row = _rowFor(libraryId);
      if (row == null) {
        return;
      }
      _updateRow(
        row.copyWith(
          scanInProgress: false,
          metadataRefreshInProgress: false,
        ),
      );
      _busyResetTimers.remove(libraryId);
    });
  }

  Future<void> _openLibraryEdit(Md3eLibraryEditPageIntent intent) async {
    await showMd3eLibraryEdit(context: context, intent: intent);
  }

  void _defaultAddLocalLibrary() {
    unawaited(_openLibraryEdit(Md3eLibraryEditPageIntent.createLocal));
  }

  void _defaultAddRemoteLibrary() {
    unawaited(_openLibraryEdit(Md3eLibraryEditPageIntent.createRemote));
  }

  Future<void> _defaultLibraryAction(
    String libraryId,
    Md3eHomeLibraryManagementAction action,
  ) async {
    final Md3eHomeLibraryDashboardRow? row = _rowFor(libraryId);
    if (row == null) {
      return;
    }

    switch (action) {
      case Md3eHomeLibraryManagementAction.edit:
        final Md3eLibraryEditPageIntent intent =
            row.kind == Md3eHomeLibraryKind.remote
            ? Md3eLibraryEditPageIntent.editRemote
            : Md3eLibraryEditPageIntent.editLocal;
        await _openLibraryEdit(intent);
      case Md3eHomeLibraryManagementAction.scan:
      case Md3eHomeLibraryManagementAction.deepScan:
        _updateRow(row.copyWith(scanInProgress: true));
        _scheduleBusyReset(libraryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lab 预览：未执行 Library sync')),
          );
        }
      case Md3eHomeLibraryManagementAction.refreshMetadata:
        _updateRow(row.copyWith(metadataRefreshInProgress: true));
        _scheduleBusyReset(libraryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lab 预览：未执行 Metadata refresh')),
          );
        }
      case Md3eHomeLibraryManagementAction.delete:
        final bool confirmed = await showMd3eHomeLibraryDeleteConfirmDialog(
          context: context,
          libraryDisplayName: row.displayName,
        );
        if (!confirmed || !mounted) {
          return;
        }
        setState(() {
          _libraries = _libraries
              .where(
                (Md3eHomeLibraryDashboardRow item) =>
                    item.libraryId != libraryId,
              )
              .toList(growable: false);
        });
    }
  }

  void _handleLibraryAction(
    String libraryId,
    Md3eHomeLibraryManagementAction action,
  ) {
    if (widget.onLibraryAction != null) {
      widget.onLibraryAction!(libraryId, action);
      return;
    }
    unawaited(_defaultLibraryAction(libraryId, action));
  }

  @override
  Widget build(BuildContext context) {
    return Md3eHomePage(
      libraries: _libraries,
      onOpenNavigation: widget.onOpenNavigation,
      onLibraryOpen: widget.onLibraryOpen,
      onLibraryAction: _handleLibraryAction,
      onAddLocalLibrary:
          widget.onAddLocalLibrary ?? _defaultAddLocalLibrary,
      onAddRemoteLibrary:
          widget.onAddRemoteLibrary ?? _defaultAddRemoteLibrary,
      onLibrariesReorder: widget.enableReorder ? _handleReorder : null,
    );
  }
}
