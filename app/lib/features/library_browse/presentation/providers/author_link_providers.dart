import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<Future<void> Function(String)> openAuthorLinkCommandProvider =
    requiredProvider('openAuthorLinkCommandProvider');
