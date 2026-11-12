import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/contracts/app_navigator.dart';

final Provider<AppNavigator> appNavigatorProvider = injectedDi(
  'appNavigatorProvider',
);
