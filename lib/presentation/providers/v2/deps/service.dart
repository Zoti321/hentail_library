// == service ==
import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:hentai_library/data/services/comic/resource_scanner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service.g.dart';

@Riverpod(keepAlive: true)
ResourceScanner resourceScanner(Ref ref) => ResourceScanner();

@Riverpod(keepAlive: true)
ResourceParser resourceParser(Ref ref) => ResourceParser();
