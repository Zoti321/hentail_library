import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_home_page_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_aggregate_counts.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_aggregate_stats_section.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_page_header.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_page_preview_data.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 首页（Widgetbook / 壳内 pane）：问候 + 漫画库概览；其余 section 后续补。
class Md3eHomePage extends StatelessWidget {
  Md3eHomePage({
    super.key,
    List<Md3eHomeLibraryDashboardRow>? libraries,
    Md3eHomeAggregateCounts? aggregateCounts,
    this.onOpenNavigation,
    this.onLibraryOpen,
    this.onLibraryAction,
    this.onAddLocalLibrary,
    this.onAddRemoteLibrary,
    this.onLibrariesReorder,
  })  : libraries = libraries ?? Md3eHomePagePreviewData.sampleLibraries(),
        aggregateCounts =
            aggregateCounts ?? Md3eHomePagePreviewData.sampleAggregateCounts();

  final List<Md3eHomeLibraryDashboardRow> libraries;
  final Md3eHomeAggregateCounts aggregateCounts;
  final VoidCallback? onOpenNavigation;
  final ValueChanged<String>? onLibraryOpen;
  final void Function(String libraryId, Md3eHomeLibraryManagementAction action)?
      onLibraryAction;
  final VoidCallback? onAddLocalLibrary;
  final VoidCallback? onAddRemoteLibrary;
  final void Function(int oldIndex, int newIndex)? onLibrariesReorder;

  @override
  Widget build(BuildContext context) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(windowWidth);
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final double horizontalPadding =
        Md3eHomePageMetrics.contentHorizontalPadding(sizeClass);
    final double maxWidth = Md3eHomePageMetrics.contentMaxWidth(sizeClass);
    final String greeting = l10n.homeGreetingReader(
      l10n.homeGreetingPhraseForHour(DateTime.now().hour),
    );

    final Widget body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Md3eHomePageHeader(onOpenNavigation: onOpenNavigation),
              Text(
                greeting,
                style: theme.typeScale.titleMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(
                height: Md3eHomePageMetrics.greetingToSectionSpacing(sizeClass),
              ),
              Md3eHomeAggregateStatsSection(counts: aggregateCounts),
              SizedBox(
                height: Md3eHomePageMetrics.sectionVerticalSpacing(sizeClass),
              ),
              Md3eHomeLibraryManagementSection(
                libraries: libraries,
                onLibraryOpen: onLibraryOpen,
                onLibraryAction: onLibraryAction,
                onAddLocalLibrary: onAddLocalLibrary,
                onAddRemoteLibrary: onAddRemoteLibrary,
                onLibrariesReorder: onLibrariesReorder,
              ),
              SizedBox(
                height: Md3eHomePageMetrics.sectionVerticalSpacing(sizeClass),
              ),
            ],
          ),
        ),
      ),
    );

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(scheme),
      child: SingleChildScrollView(
        child: body,
      ),
    );
  }
}
