import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

/// home owner 的 Repository token（#515；实现由 bootstrap 注入）。

final Provider<HomePageRepository> homePageRepoProvider = requiredProvider(
  'homePageRepoProvider',
);
