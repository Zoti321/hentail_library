import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/navigation/library_return_breadcrumb.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

class SeriesDetailLoading extends StatelessWidget {
  const SeriesDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class SeriesDetailError extends StatelessWidget {
  const SeriesDetailError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '加载失败：$error',
              style: TextStyle(color: colorScheme.error, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const LibraryReturnBreadcrumb(),
          ],
        ),
      ),
    );
  }
}

class SeriesNotFound extends StatelessWidget {
  const SeriesNotFound({super.key, required this.seriesName});

  final String seriesName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              '未找到系列「$seriesName」',
              style: TextStyle(fontSize: 14, color: cs.textTertiary),
            ),
            const SizedBox(height: 12),
            const LibraryReturnBreadcrumb(),
          ],
        ),
      ),
    );
  }
}
