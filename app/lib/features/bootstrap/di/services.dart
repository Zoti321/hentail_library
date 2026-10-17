import 'package:hentai_library/features/app_settings/data/services/app_update/app_update_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:hentai_library/features/named_metadata/di/download_providers.dart';
export 'package:hentai_library/features/read_session/di/session_providers.dart';

part 'services.g.dart';

@Riverpod(keepAlive: true)
AppUpdateService appUpdateService(Ref ref) => AppUpdateService();
