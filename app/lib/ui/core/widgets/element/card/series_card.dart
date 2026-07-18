import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';
import 'package:hentai_library/ui/core/widgets/element/image/series_cover_content.dart';

class SeriesCard extends StatelessWidget {
  const SeriesCard({
    super.key,
    required this.series,
    this.onTap,
    this.onSecondaryTapUp,
  });

  final Series series;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    return CatalogCoverCardShell(
      onTap: onTap,
      onSecondaryTapUp: onSecondaryTapUp,
      cover: SeriesCoverContent(
        seriesId: series.id,
        priority: ThumbnailPriority.high,
      ),
      info: (bool isHover) => _SeriesCardInfo(series: series, isHover: isHover),
    );
  }
}

class _SeriesCardInfo extends StatelessWidget {
  const _SeriesCardInfo({required this.series, required this.isHover});

  final Series series;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: tokens.text.bodyMd,
            fontWeight: FontWeight.w600,
            fontFamily: 'MI_Sans_Regular',
            height: 1.25,
            color: isHover ? cs.primary : cs.hentai.textPrimary,
          ),
          child: Text(
            series.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          series.volumeCountLabel,
          style: TextStyle(
            fontSize: tokens.text.labelXs - 1,
            color: cs.hentai.textTertiary,
          ),
        ),
      ],
    );
  }
}
