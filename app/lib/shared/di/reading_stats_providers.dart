import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/home_page_counts_port.dart';

final Provider<HomePageCountsPort> homePageCountsPortProvider =
    Provider<HomePageCountsPort>(
      (Ref ref) => throw UnimplementedError(
        'homePageCountsPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
