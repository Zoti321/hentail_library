import 'package:hentai_library/data/services/app_update/app_update_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'services.g.dart';

@Riverpod(keepAlive: true)
AppUpdateService appUpdateService(Ref ref) => AppUpdateService();
