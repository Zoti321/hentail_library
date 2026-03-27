import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/providers/directory/directory_providers.dart';

final pathsStreamProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(pathRepoProvider).getPathsStream();
});
