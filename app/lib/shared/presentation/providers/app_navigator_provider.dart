import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:hentai_library/shared/application/contracts/app_navigator.dart';

final Provider<AppNavigator> appNavigatorProvider = requiredProvider(
  'appNavigatorProvider',
);
