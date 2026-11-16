import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/application/app_update_gateway.dart';
import 'package:hentai_library/features/app_settings/application/check_app_update_use_case.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<AppUpdateGateway> appUpdateGatewayProvider = requiredProvider(
  'appUpdateGatewayProvider',
);

final checkAppUpdateUseCaseProvider = Provider<CheckAppUpdateUseCase>(
  (ref) => CheckAppUpdateUseCase(
    fetchLatestRelease: ref
        .watch(appUpdateGatewayProvider)
        .fetchLatestStableRelease,
    readDismissedVersion: () =>
        ref.read(settingsProvider).asData?.value.dismissedUpdateVersion,
  ),
);
