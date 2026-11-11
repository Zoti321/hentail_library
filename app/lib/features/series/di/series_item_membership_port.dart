import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';
import 'package:hentai_library/features/series/public/di/series_repository_providers.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/shared/domain/ports/series_item_membership_port.dart';

final class SeriesItemMembershipPortImpl implements SeriesItemMembershipPort {
  SeriesItemMembershipPortImpl(this._repository);

  final SeriesRepository _repository;

  @override
  Future<SeriesItemMembership?> findMembershipByComicId(String comicId) =>
      _repository.findMembershipByComicId(comicId);
}

SeriesItemMembershipPort createSeriesItemMembershipPort(Ref ref) =>
    SeriesItemMembershipPortImpl(ref.read(seriesRepoProvider));
