import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/md3e_desktop_title_bar_metrics.dart';
import 'package:hentai_library/md3e/widgets/md3e_desktop_window_controls.dart';
import 'package:hentai_library/md3e/widgets/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' show WidgetStatePropertyAll;

/// Desktop window title strip: global search aligned to the pane + window controls.
///
/// Menu for the navigation rail lives in [Md3eNavigationRail], not here. The
/// region above the rail column is reserved for platform window drag (Lab: inert).
class Md3eDesktopTitleBar extends StatelessWidget {
  const Md3eDesktopTitleBar({
    super.key,
    this.railWidth = 0,
    this.searchLeadingInset,
    this.searchHint = '搜索…',
    this.searchController,
    this.onSearchSubmitted,
    this.searchWidth = Md3eDesktopTitleBarMetrics.defaultSearchWidth,
    this.showWindowControls = true,
    this.onWindowMinimize,
    this.onWindowMaximize,
    this.onWindowClose,
  });

  /// Simulated rail column width for **isolated** title-bar previews only.
  final double railWidth;

  /// Space before the search field. When null, uses [railWidth] + pane gutter (24).
  /// Use `0` in [Md3eDesktopShell] so search aligns with the main pane leading edge.
  final double? searchLeadingInset;

  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;
  final double searchWidth;
  final bool showWindowControls;
  final VoidCallback? onWindowMinimize;
  final VoidCallback? onWindowMaximize;
  final VoidCallback? onWindowClose;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    final M3EColorScheme scheme = m3e.colorScheme;
    final double paneGutter = m3e.spacing.lg;

    return SizedBox(
      height: Md3eDesktopTitleBarMetrics.height,
      width: double.infinity,
      child: ColoredBox(
        color: scheme.surfaceContainerLow,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double controlsWidth = showWindowControls
                ? Md3eDesktopTitleBarMetrics.windowControlsWidth +
                    Md3eDesktopTitleBarMetrics.windowControlsTrailing
                : 0;
            final double leadingWidth =
                searchLeadingInset ?? (railWidth + paneGutter);
            final double availableSearch =
                constraints.maxWidth - leadingWidth - controlsWidth;
            final double searchMax =
                availableSearch < 0 ? 0.0 : availableSearch;
            final double resolvedSearchWidth = searchWidth.clamp(0, searchMax);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (leadingWidth > 0) SizedBox(width: leadingWidth),
                if (resolvedSearchWidth > 0)
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: resolvedSearchWidth,
                        height: Md3eDesktopTitleBarMetrics.searchHeight,
                        child: _Md3eTitleBarSearchField(
                          hintText: searchHint,
                          controller: searchController,
                          onSubmitted: onSearchSubmitted,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (showWindowControls)
                  Padding(
                    padding: const EdgeInsets.only(
                      right:
                          Md3eDesktopTitleBarMetrics.windowControlsTrailing,
                    ),
                    child: Md3eDesktopWindowControls(
                      onMinimize: onWindowMinimize,
                      onMaximize: onWindowMaximize,
                      onClose: onWindowClose,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Md3eTitleBarSearchField extends StatelessWidget {
  const _Md3eTitleBarSearchField({
    required this.hintText,
    this.controller,
    this.onSubmitted,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    final M3EColorScheme scheme = m3e.colorScheme;
    final M3ESearchBarTheme compactSearch = m3e.searchBarTheme.copyWith(
      minHeight: Md3eDesktopTitleBarMetrics.searchHeight,
      minWidth: 0,
      maxWidth: double.infinity,
      unfocusedMargin: 0,
      focusedMargin: 0,
      expandOnFocus: false,
      iconSize: 20,
    );

    return M3ETheme(
      data: m3e.copyWith(searchBarTheme: compactSearch),
      child: M3ESearchBar(
        controller: controller,
        hintText: hintText,
        onSubmitted: onSubmitted,
        margin: 0,
        expandOnFocus: false,
        leading: Icon(
          Icons.search,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
        constraints: const BoxConstraints(
          minHeight: Md3eDesktopTitleBarMetrics.searchHeight,
          maxHeight: Md3eDesktopTitleBarMetrics.searchHeight,
        ),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

/// Convenience rail width for title bar layout next to a collapsed rail.
double md3eDesktopTitleBarRailWidth({required bool railExtended}) {
  return railExtended
      ? Md3eNavigationRailMetrics.expandedWidth
      : Md3eNavigationRailMetrics.collapsedWidth;
}
