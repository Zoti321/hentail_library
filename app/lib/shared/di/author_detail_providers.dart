import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/author_detail_port.dart';

/// 按作者名打开作者详情 token；实现与工厂见 `features/library_browse/public.dart`。

final Provider<AuthorDetailPort> authorDetailPortProvider = injectedDi(
  'authorDetailPortProvider',
);
