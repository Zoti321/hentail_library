import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/resource_metadata/domain/writeback_gateway.dart';

final writebackGatewayProvider = Provider<WritebackGateway>((ref) {
  throw StateError('WritebackGateway must be bound by composition');
});

final writebackRevisionProvider = NotifierProvider<WritebackRevision, int>(
  WritebackRevision.new,
);

class WritebackRevision extends Notifier<int> {
  @override
  int build() => 0;
  void changed() => state++;
}

final writebackEnabledProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, id) {
      return ref.watch(writebackGatewayProvider).isEnabled(id);
    });
