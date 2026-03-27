import 'package:hentai_library/data/repository/dir_repo.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/presentation/providers/core/core_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directory_providers.g.dart';

@Riverpod(keepAlive: true)
PathRepository pathRepo(Ref ref) =>
    PathRepositoryImpl(ref.read(savedPathDaoProvider));
