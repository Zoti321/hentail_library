import 'dart:async';

import 'package:hentai_library/infrastructure/events/stream_domain_event_bus.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:test/test.dart';

/// ADR-0039 §6 不变量：同步投递、类型过滤、多订阅、不重放、可释放。
void main() {
  late StreamDomainEventBus bus;
  late List<DomainEvent> received;

  setUp(() {
    bus = StreamDomainEventBus();
    received = <DomainEvent>[];
  });

  tearDown(() => bus.dispose());

  test('publish delivers synchronously', () {
    bus.on<DomainEvent>().listen(received.add);

    bus.publish(const ComicMetadataPersisted());
    expect(received, hasLength(1));

    bus.publish(const LibraryCatalogChanged(CatalogChangeSource.sync));
    expect(received, hasLength(2));
  });

  test('on<T> filters by runtime type', () {
    final List<LibraryCatalogChanged> catalogs = <LibraryCatalogChanged>[];
    bus.on<LibraryCatalogChanged>().listen(catalogs.add);
    bus.on<ComicMetadataPersisted>().listen((_) => fail('wrong type'));

    bus.publish(const ComicsTrashed(<String>['c1']));
    bus.publish(
      const LibraryCatalogChanged(CatalogChangeSource.metadataRefresh),
    );

    expect(catalogs, hasLength(1));
    expect(catalogs.single.source, CatalogChangeSource.metadataRefresh);
  });

  test('broadcast supports multiple independent subscribers', () {
    int a = 0;
    int b = 0;
    bus.on<DomainEvent>().listen((_) => a++);
    bus.on<DomainEvent>().listen((_) => b++);

    bus.publish(const ComicsRestored(<String>['c1']));

    expect(a, 1);
    expect(b, 1);
  });

  test('no replay for events published before subscribe', () {
    bus.publish(const ComicMetadataPersisted());

    final List<DomainEvent> late = <DomainEvent>[];
    bus.on<DomainEvent>().listen(late.add);

    expect(late, isEmpty);
  });

  test('dispose closes the stream', () async {
    final Completer<void> closed = Completer<void>();
    bus.on<DomainEvent>().listen((_) {}, onDone: closed.complete);
    bus.dispose();
    await expectLater(closed.future, completes);
  });
}
