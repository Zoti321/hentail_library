import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/ui/ports/author_detail_port.dart';

/// 按作者名打开作者详情的端口（#292）：由 bootstrap 通过 `overrideWith` 注入。
final Provider<AuthorDetailPort> authorDetailPortProvider =
    Provider<AuthorDetailPort>(
      (Ref ref) => throw UnimplementedError(
        'authorDetailPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
