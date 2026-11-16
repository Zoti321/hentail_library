import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<AppSettingRepository> appSettingRepositoryProvider =
    requiredProvider('appSettingRepositoryProvider');
