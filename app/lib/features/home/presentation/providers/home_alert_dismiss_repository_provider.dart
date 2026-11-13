import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/home/domain/home_alert_dismiss_repository.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<HomeAlertDismissRepository> homeAlertDismissRepositoryProvider =
    requiredProvider('homeAlertDismissRepositoryProvider');
