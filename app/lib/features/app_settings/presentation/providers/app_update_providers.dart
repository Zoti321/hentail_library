import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/application/app_update_gateway.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<AppUpdateGateway> appUpdateGatewayProvider = requiredProvider(
  'appUpdateGatewayProvider',
);
