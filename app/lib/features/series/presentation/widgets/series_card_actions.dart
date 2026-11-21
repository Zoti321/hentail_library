import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/presentation/actions/series_metadata_edit_presenters.dart';
import 'package:hentai_library/features/series/presentation/providers/series_repository_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/app_exception.dart';
import 'package:hentai_library/shared/presentation/providers/file_explorer_providers.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 库页系列卡面最小只读投影（record）。
typedef SeriesCardProjection = ({String seriesId, String name});

/// 包裹 MD3E 系列卡片：仅桌面端鼠标右键弹出 [M3EMenu]
///（在资源管理器中打开、编辑）；移动端无上下文菜单。
///
/// 与 [ComicCardActions] 同构：选择模式下 [enabled] 为 false 时不弹菜单。
class SeriesCardActions extends ConsumerWidget {
  const SeriesCardActions({
    super.key,
    required this.seriesId,
    required this.name,
    required this.child,
    this.enabled = true,
  });

  SeriesCardActions.fromBrowse({
    super.key,
    required SeriesCardProjection item,
    required this.child,
    this.enabled = true,
  }) : seriesId = item.seriesId,
       name = item.name;

  final String seriesId;
  final String name;
  final Widget child;

  /// 选择模式下设为 false，桌面端右键不弹出操作菜单。
  final bool enabled;

  static bool _isDesktop(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled || !_isDesktop(context)) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapUp: (TapUpDetails details) =>
          _showMenu(context, ref, details.globalPosition),
      child: child,
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, Offset globalPosition) {
    final AppLocalizations l10n = context.l10n;
    unawaited(
      showPointerContextMenu<void>(
        context: context,
        globalPosition: globalPosition,
        children: <M3EMenuNode>[
          M3EMenuEntry(
            label: l10n.comicDetailShowInExplorer,
            leading: const Icon(LucideIcons.folderOpen),
            onPressed: () => _openInExplorer(context, ref),
          ),
          M3EMenuEntry(
            label: l10n.comicDetailEditMetadata,
            leading: const Icon(LucideIcons.squarePen),
            onPressed: () => _editMetadata(context, ref),
          ),
        ],
      ),
    );
  }

  Future<Series?> _loadSeries(WidgetRef ref) {
    return ref.read(seriesRepoProvider).findById(seriesId);
  }

  Future<void> _openInExplorer(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    try {
      final Series? series = await _loadSeries(ref);
      if (series == null) {
        if (context.mounted) {
          showErrorSnackbar(
            context,
            AppException(l10n.comicDetailShowInExplorerFailed),
          );
        }
        return;
      }
      await ref.read(showInFileExplorerProvider)(series.folderPath);
    } on Object catch (error, stackTrace) {
      debugPrint('showInFileExplorer failed for series "$seriesId": $error');
      if (!context.mounted) {
        return;
      }
      final AppException failure = error is AppException
          ? error
          : AppException(
              l10n.comicDetailShowInExplorerFailed,
              cause: error,
              stackTrace: stackTrace,
            );
      showErrorSnackbar(context, failure);
    }
  }

  Future<void> _editMetadata(BuildContext context, WidgetRef ref) async {
    try {
      final Series? series = await _loadSeries(ref);
      if (!context.mounted) {
        return;
      }
      if (series == null) {
        showErrorSnackbar(
          context,
          AppException(context.l10n.seriesDetailNotFound(name)),
        );
        return;
      }
      await showSeriesMetadataEdit(context: context, series: series);
    } on Object catch (error) {
      if (context.mounted) {
        showErrorSnackbar(context, error);
      }
    }
  }
}
