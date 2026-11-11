import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/series_item_membership_port.dart';

/// Series 成员归属窄读口（ADR-0042）；实现由 series owner bootstrap override 注入。
final Provider<SeriesItemMembershipPort> seriesItemMembershipPortProvider =
    injectedDi('seriesItemMembershipPortProvider');
