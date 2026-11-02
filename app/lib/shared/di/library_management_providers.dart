import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/library_management_port.dart';

/// 库管理 UI 命令 token；实现与工厂见 `features/library_admin/public.dart`。

final Provider<LibraryManagementPort> libraryManagementPortProvider =
    Provider<LibraryManagementPort>(
      (Ref ref) => throw UnimplementedError(
        'libraryManagementPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
