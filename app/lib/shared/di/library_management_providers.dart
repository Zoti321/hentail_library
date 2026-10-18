import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/shared/ui/ports/author_detail_port.dart';
import 'package:hentai_library/shared/ui/ports/library_management_port.dart';

final Provider<LibraryManagementPort> libraryManagementPortProvider =
    Provider<LibraryManagementPort>(
      (Ref ref) => throw UnimplementedError(
        'libraryManagementPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<AuthorDetailPort> authorDetailPortProvider =
    Provider<AuthorDetailPort>(
      (Ref ref) => throw UnimplementedError(
        'authorDetailPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

/// 仅持有 [BuildContext]（无 WidgetRef）的调用点：回到当前库浏览页。
///
/// 无 ProviderScope 时回退到全部库页，与历史行为一致。
void goCurrentLibraryBrowseFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(
      context,
    ).read(libraryManagementPortProvider).goCurrentLibraryBrowse(context);
  } catch (_) {
    context.go(LibrariesRoutes.all);
  }
}
