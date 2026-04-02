import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';

class SeriesManagementLoadingState extends StatelessWidget {
  const SeriesManagementLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class SeriesManagementErrorState extends StatelessWidget {
  const SeriesManagementErrorState({super.key, required this.error});

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

class SeriesManagementEmptyState extends StatelessWidget {
  const SeriesManagementEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '暂无系列',
          style: TextStyle(fontSize: 14, color: cs.textTertiary),
        ),
      ),
    );
  }
}

