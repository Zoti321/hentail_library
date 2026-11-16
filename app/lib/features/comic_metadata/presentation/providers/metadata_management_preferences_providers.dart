import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<Future<bool> Function()> mergeConfirmationSkippedQueryProvider =
    requiredProvider('mergeConfirmationSkippedQueryProvider');
final Provider<Future<void> Function(bool)>
setMergeConfirmationSkippedCommandProvider = requiredProvider(
  'setMergeConfirmationSkippedCommandProvider',
);
