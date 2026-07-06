import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/metadata/view_models/series_management_notifier.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_panel_height.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesManagementPanel extends StatelessWidget {
  const SeriesManagementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final EdgeInsets contentPadding = tokens.layout.contentAreaPadding.copyWith(
      bottom: tokens.layout.contentVerticalPadding + 24,
    );
    return Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Header(),
          const SizedBox(height: 20),
          const Expanded(child: _FilteredSeriesSection()),
        ],
      ),
    );
  }
}

class _FilteredSeriesSection extends ConsumerWidget {
  const _FilteredSeriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Series>> seriesAsync = ref.watch(
      filteredSeriesProvider,
    );
    return seriesAsync.when(
      data: (List<Series> series) {
        if (series.isEmpty) {
          return const _SeriesManagementEmptyState();
        }
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cardHeight =
                MetadataPanelHeightCalculator.calculateCardHeight(
                  constraints: constraints,
                  itemCount: series.length,
                  config: _SeriesStyles.listHeightConfig,
                );
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                height: cardHeight,
                child: _SeriesListCard(series: series),
              ),
            );
          },
        );
      },
      loading: () => const _SeriesManagementLoadingState(),
      error: (Object e, StackTrace _) => _SeriesManagementErrorState(error: e),
    );
  }
}

class _SeriesStyles {
  const _SeriesStyles._();
  static const MetadataPanelHeightConfig listHeightConfig =
      MetadataPanelHeightConfig(
        minHeight: 240,
        maxHeight: 640,
        heightFactor: 0.78,
        headerHeight: 52,
        estimatedRowHeight: 56,
      );
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '系列管理',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: cs.hentai.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '系列由 Library 同步时根据文件夹结构自动生成；可在系列详情页编辑名称、连载状态与漫画总数',
                style: TextStyle(color: cs.hentai.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          child: CustomTextField(
            hintText: '搜索系列名称…',
            onChanged: (String value) =>
                ref.read(seriesFilterProvider.notifier).setQuery(value),
          ),
        ),
      ],
    );
  }
}

class _SeriesListCard extends StatelessWidget {
  const _SeriesListCard({required this.series});

  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.hentai.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: cs.hentai.borderSubtle),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    LucideIcons.layers,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '全部系列',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.hentai.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '共 ${series.length} 条',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.hentai.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: series.length,
                itemBuilder: (BuildContext context, int index) {
                  return _SeriesRow(series: series[index]);
                },
                separatorBuilder: (BuildContext context, int index) =>
                    Divider(height: 1, color: cs.hentai.borderSubtle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: () {
          final String encoded = Uri.encodeComponent(series.id);
          context.go('/series/$encoded');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      series.volumeCountLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.hentai.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: cs.hentai.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesManagementLoadingState extends StatelessWidget {
  const _SeriesManagementLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SeriesManagementErrorState extends StatelessWidget {
  const _SeriesManagementErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        '加载失败：$error',
        style: TextStyle(color: cs.error, fontSize: 14),
      ),
    );
  }
}

class _SeriesManagementEmptyState extends StatelessWidget {
  const _SeriesManagementEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '暂无系列。请确保 Library 路径中存在包含多个漫画的文件夹，同步后会自动生成系列。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: cs.hentai.textTertiary),
        ),
      ),
    );
  }
}
