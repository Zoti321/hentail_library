/// Bootstrap 注入用的库仓储与修订 Port 工厂（实现留在 owner data 层）。
library;

import 'package:hentai_library/features/library_admin/data/adapters/library_revision_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/data/repositories/library_repository_impl.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';

LibraryRepository createLibraryRepository() => const LibraryRepositoryImpl();

LibraryRevisionPort createLibraryRevisionPort() =>
    const LibraryRevisionFrbAdapter();
