import 'package:flutter/material.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set 图片占位缩略图：v1 无 Image set 缩略图源，仅展示稳定 key 与文件名。
class ImageSetImageTile extends StatelessWidget {
  const ImageSetImageTile({
    super.key,
    required this.image,
    required this.onTap,
  });

  final ImageSetImage image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                image.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typeScale.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
