import 'dart:io';

import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/services/comic/scan/resource_parser.dart';
import 'package:path/path.dart' as p;

class ResourceParseDispatcher {
  ResourceParseDispatcher({
    required List<ResourceParser> parsers,
    required ParseContext parseContext,
  }) : _parseContext = parseContext,
       _parsers = List<ResourceParser>.unmodifiable(parsers),
       _dirParser = _resolveDirParser(parsers),
       _fileParsers = _buildFileParsers(parsers);

  final ParseContext _parseContext;
  final List<ResourceParser> _parsers;
  final ResourceParser? _dirParser;
  final List<ResourceParser> _fileParsers;
  late final Map<String, List<ResourceParser>> _fileParserIndex =
      _buildFileParserIndex(_fileParsers);

  static ResourceParser? _resolveDirParser(List<ResourceParser> parsers) {
    for (final ResourceParser parser in parsers) {
      if (parser.type == ResourceType.dir) {
        return parser;
      }
    }
    return null;
  }

  static List<ResourceParser> _buildFileParsers(List<ResourceParser> parsers) {
    return parsers
        .where((ResourceParser parser) => parser.type != ResourceType.dir)
        .toList(growable: false);
  }

  static Map<String, List<ResourceParser>> _buildFileParserIndex(
    List<ResourceParser> fileParsers,
  ) {
    final Map<String, List<ResourceParser>> index =
        <String, List<ResourceParser>>{};
    for (final ResourceParser parser in fileParsers) {
      final String? extension = _resourceTypeToExtension(parser.type);
      if (extension == null) {
        continue;
      }
      final List<ResourceParser> existing =
          index[extension] ?? <ResourceParser>[];
      index[extension] = <ResourceParser>[...existing, parser];
    }
    return index;
  }

  static String? _resourceTypeToExtension(ResourceType type) {
    return switch (type) {
      ResourceType.zip => '.zip',
      ResourceType.cbz => '.cbz',
      ResourceType.epub => '.epub',
      ResourceType.cbr => '.cbr',
      ResourceType.rar => '.rar',
      _ => null,
    };
  }

  Future<ParsedResource?> parseDirectory(Directory dir) async {
    final ResourceParser? dirParser = _dirParser;
    if (dirParser == null || !dirParser.supports(dir)) {
      return null;
    }
    return dirParser.parse(dir, _parseContext);
  }

  Future<ParsedResource?> parseFile(File file) async {
    final String name = p.basename(file.path);
    if (name.startsWith('.')) {
      return null;
    }
    final String extension = p.extension(file.path).toLowerCase();
    final List<ResourceParser> indexedParsers =
        _fileParserIndex[extension] ?? const <ResourceParser>[];
    final List<ResourceParser> parsersToTry = indexedParsers.isNotEmpty
        ? indexedParsers
        : _parsers;
    for (final ResourceParser parser in parsersToTry) {
      if (parser.type == ResourceType.dir) {
        continue;
      }
      if (parser.supports(file)) {
        return parser.parse(file, _parseContext);
      }
    }
    return null;
  }
}

