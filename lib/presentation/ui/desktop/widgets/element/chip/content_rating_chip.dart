import 'package:flutter/material.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

class ContentRatingChip extends StatelessWidget {
  const ContentRatingChip({super.key, required this.rating});

  final ContentRating rating;

  static const double chipWidth = 48;
  static const double chipHeight = 18;

  @override
  Widget build(BuildContext context) {
    final _ContentRatingVisual visual = _resolveVisual(
      colorScheme: Theme.of(context).colorScheme,
      rating: rating,
    );

    return Container(
      width: chipWidth,
      height: chipHeight,
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: visual.borderColor),
      ),
      child: Center(
        child: Text(
          visual.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: visual.textColor,
            height: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  _ContentRatingVisual _resolveVisual({
    required ColorScheme colorScheme,
    required ContentRating rating,
  }) {
    switch (rating) {
      case ContentRating.unknown:
        return _ContentRatingVisual(
          label: '未知',
          backgroundColor: colorScheme.surfaceContainerHighest,
          borderColor: colorScheme.borderSubtle,
          textColor: colorScheme.textTertiary,
        );
      case ContentRating.safe:
        return _ContentRatingVisual(
          label: '全年龄',
          backgroundColor: colorScheme.success.withAlpha(30),
          borderColor: colorScheme.success.withAlpha(90),
          textColor: colorScheme.success,
        );
      case ContentRating.r18:
        return _ContentRatingVisual(
          label: 'NSFW',
          backgroundColor: colorScheme.warning.withAlpha(30),
          borderColor: colorScheme.warning.withAlpha(90),
          textColor: colorScheme.warning,
        );
    }
  }
}

class _ContentRatingVisual {
  const _ContentRatingVisual({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}
