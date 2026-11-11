import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

/// home owner 的 Repository token（#515；实现由 bootstrap 注入）。

final Provider<HomePageRepository> homePageRepoProvider = injectedDi(
  'homePageRepoProvider',
);
