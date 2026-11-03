import 'package:hentai_library/features/app_settings/data/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
AppSettingRepository createAppSettingRepository() => AppSettingRepositoryImpl();
