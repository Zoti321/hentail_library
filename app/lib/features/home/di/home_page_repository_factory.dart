import 'package:hentai_library/features/home/data/repositories/home_page_repository_impl.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
HomePageRepository createHomePageRepository() => const HomePageRepositoryImpl();
