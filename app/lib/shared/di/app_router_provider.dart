import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:go_router/go_router.dart';

final Provider<GoRouter> appRouterProvider = injectedDi('appRouterProvider');
