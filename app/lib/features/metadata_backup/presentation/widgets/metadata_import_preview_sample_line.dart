import 'package:flutter/material.dart';
import 'package:hentai_library/features/metadata_backup/presentation/widgets/ellipsis_middle_path.dart';

class MetadataImportPreviewSampleLine extends StatelessWidget {
  const MetadataImportPreviewSampleLine({
    super.key,
    required this.primary,
    required this.secondary,
    required this.path,
  });

  final String primary;
  final String secondary;
  final String path;

  @override
  Widget build(BuildContext context) {
    final String displayPath = ellipsisMiddlePath(path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(primary, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(secondary, style: Theme.of(context).textTheme.bodySmall),
          Tooltip(
            message: path,
            child: Text(
              displayPath,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
