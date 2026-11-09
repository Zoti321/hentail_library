import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/event_bus_overrides.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';
import 'package:hentai_library/shared/di/event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:test/test.dart';

void main() {
  ProviderContainer container() {
    final ProviderContainer c = ProviderContainer(
      overrides: eventBusOverrides(),
    );
    addTearDown(c.dispose);
    // 订阅方须先建立订阅：事件流不重放。
    c.read(domainEventRevisionsProvider);
    return c;
  }

  test('dictionary write bumps both revisions', () {
    final ProviderContainer c = container();
    c
        .read(appEventBusProvider)
        .publish(const ComicMetadataPersisted(tagsWritten: true));

    final DomainEventRevisionsState state = c.read(
      domainEventRevisionsProvider,
    );
    expect(state.dictionaryRevision, 1);
    expect(state.metadataSaveRevision, 1);
  });

  test('metadata-only write bumps save revision only', () {
    final ProviderContainer c = container();
    c.read(appEventBusProvider).publish(const ComicMetadataPersisted());

    final DomainEventRevisionsState state = c.read(
      domainEventRevisionsProvider,
    );
    expect(state.dictionaryRevision, 0);
    expect(state.metadataSaveRevision, 1);
  });

  test('catalog change bumps catalog revision only', () {
    final ProviderContainer c = container();
    c
        .read(appEventBusProvider)
        .publish(const LibraryCatalogChanged(CatalogChangeSource.sync));

    final DomainEventRevisionsState state = c.read(
      domainEventRevisionsProvider,
    );
    expect(state.catalogRevision, 1);
    expect(state.dictionaryRevision, 0);
    expect(state.metadataSaveRevision, 0);
  });

  test('trash / restore bump catalog revision only', () {
    final ProviderContainer c = container();
    c.read(appEventBusProvider).publish(const ComicsTrashed(<String>['c1']));
    c.read(appEventBusProvider).publish(const ComicsRestored(<String>['c1']));

    final DomainEventRevisionsState state = c.read(
      domainEventRevisionsProvider,
    );
    expect(state.catalogRevision, 2);
    expect(state.metadataSaveRevision, 0);
  });

  test('no event published before subscribe is replayed', () {
    final ProviderContainer c = ProviderContainer(
      overrides: eventBusOverrides(),
    );
    addTearDown(c.dispose);
    c.read(appEventBusProvider).publish(const ComicMetadataPersisted());
    c.read(domainEventRevisionsProvider);

    expect(c.read(domainEventRevisionsProvider).metadataSaveRevision, 0);
  });
}
