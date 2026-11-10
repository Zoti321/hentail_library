/// Bootstrap 注入用的库仓储与修订 Port 工厂（实现留在 owner data 层）。
library;

import 'package:hentai_library/features/library_admin/data/repositories/library_repository_impl.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';

LibraryRepository createLibraryRepository() => const LibraryRepositoryImpl();
