import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(
  (Ref ref) =>
      throw UnimplementedError('appRouterProvider 未注入，请在 bootstrap 中 override'),
);
