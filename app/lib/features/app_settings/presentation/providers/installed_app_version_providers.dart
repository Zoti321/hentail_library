import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<Future<String> Function()> installedAppVersionQueryProvider =
    requiredProvider('installedAppVersionQueryProvider');

final installedAppVersionProvider = FutureProvider<String>(
  (ref) => ref.watch(installedAppVersionQueryProvider)(),
);
