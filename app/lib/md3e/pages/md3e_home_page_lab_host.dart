import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_home_page.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_list_order.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_page_preview_data.dart';

/// Widgetbook / Lab：在本地维护库列表顺序；生产侧由 notifier + repository 接同样回调形状。
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

  @override
  Widget build(BuildContext context) {
    return Md3eHomePage(
      libraries: _libraries,
      onOpenNavigation: widget.onOpenNavigation,
      onLibraryOpen: widget.onLibraryOpen,
      onLibraryAction: widget.onLibraryAction,
      onAddLocalLibrary: widget.onAddLocalLibrary,
      onAddRemoteLibrary: widget.onAddRemoteLibrary,
      onLibrariesReorder: widget.enableReorder ? _handleReorder : null,
    );
  }
}
