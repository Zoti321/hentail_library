/// Reader 不能引用 comic（ADR-0045）；查询契约保持在共享应用层。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<ComicReadQuery> comicReadQueryProvider = requiredProvider(
  'comicReadQueryProvider',
);
