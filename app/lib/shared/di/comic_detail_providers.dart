import 'package:flutter_riverpod/flutter_riverpod.dart';

final comicResolvedPageCountProvider = FutureProvider.family<int, String>(
  (Ref ref, String comicId) => throw UnimplementedError(
    'comicResolvedPageCountProvider 未注入，请在 bootstrap 中 override',
  ),
);
