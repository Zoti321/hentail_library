import 'package:hentai_library/features/library_admin/public.dart'
    as library_admin_public;
import 'package:riverpod/misc.dart' show Override;

/// bootstrap 组装：library_admin owner 注入（#435）。
List<Override> libraryAdminSharedStateOverrides() =>
    library_admin_public.libraryAdminSharedStateOverrides();
