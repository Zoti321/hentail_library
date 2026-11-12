import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/data/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';

/// 设置仓储实现工厂。
AppSettingRepository createAppSettingRepository() => AppSettingRepositoryImpl();

/// 设置仓储 Provider（生产者拥有的唯一真源，ADR-0046）。
///
/// 取代 `shared/di` 的 `appSettingRepoProvider`：`library_admin` 等消费方只经
/// `app_settings/public` 读取，不再需要 bootstrap 转发。
final Provider<AppSettingRepository> appSettingRepositoryProvider =
    Provider<AppSettingRepository>((Ref ref) => createAppSettingRepository());
