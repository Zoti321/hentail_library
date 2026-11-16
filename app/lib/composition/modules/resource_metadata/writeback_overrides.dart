import 'package:hentai_library/features/resource_metadata/infrastructure/writeback_frb_gateway.dart';
import 'package:hentai_library/features/resource_metadata/public/providers.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> writebackOverrides() => [
  writebackGatewayProvider.overrideWithValue(WritebackFrbGateway()),
];
