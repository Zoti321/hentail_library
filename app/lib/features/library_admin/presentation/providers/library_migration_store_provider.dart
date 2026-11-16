import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/application/library_migration_store.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<LibraryMigrationStore> libraryMigrationStoreProvider =
    requiredProvider('libraryMigrationStoreProvider');
