import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hentai_library/presentation/providers/v2/deps/deps.dart';

final pathsStreamProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(pathRepoProvider).watch();
});
