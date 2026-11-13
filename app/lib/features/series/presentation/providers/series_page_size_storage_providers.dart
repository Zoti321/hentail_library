import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<Future<int> Function()> seriesDetailPageSizeQueryProvider =
    requiredProvider('seriesDetailPageSizeQueryProvider');
final Provider<Future<void> Function(int)>
setSeriesDetailPageSizeCommandProvider = requiredProvider(
  'setSeriesDetailPageSizeCommandProvider',
);
