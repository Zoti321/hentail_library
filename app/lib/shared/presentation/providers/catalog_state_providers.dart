/// 共享壳与多个 owner 的目录投影；业务真源在各 owner，组合根只接线。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<bool> libraryRevisionThrottleBusyStateProvider =
    requiredProvider('libraryRevisionThrottleBusyStateProvider');

final Provider<LibraryAgeRestrictionFilter>
libraryComicAgeRestrictionStateProvider = requiredProvider(
  'libraryComicAgeRestrictionStateProvider',
);
