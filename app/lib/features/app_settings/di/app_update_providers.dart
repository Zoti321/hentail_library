import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/data/services/app_update/app_update_service.dart';

final Provider<AppUpdateService> appUpdateServiceProvider =
    Provider<AppUpdateService>((Ref ref) => AppUpdateService());
