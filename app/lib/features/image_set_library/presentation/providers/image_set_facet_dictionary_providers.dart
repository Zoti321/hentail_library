import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_named_facet_kind.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/gateways/image_set_facet_dictionary_gateway.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_revisions.dart';

const ImageSetFacetDictionaryGateway _imageSetFacetDictionaryGateway =
    ImageSetFacetDictionaryGateway();

final imageSetFacetDictionaryProvider = FutureProvider.autoDispose
    .family<List<String>, ImageSetNamedFacetKind>((Ref ref, ImageSetNamedFacetKind kind) {
      ref.watch(
        domainEventRevisionsProvider.select(
          (DomainEventRevisionsState s) => s.dictionaryRevision,
        ),
      );
      return _imageSetFacetDictionaryGateway.listAll(kind);
    });