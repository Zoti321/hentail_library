import 'package:hentai_library/domain/models/named_facet_form_candidate.dart';

/// Comic metadata form candidate after Smart facet match ranking.
typedef SmartFacetMatchCandidate = ({
  String name,
  int attachmentCount,
  bool smartMatched,
});

/// Path-derived Author smart match signals (filename stem + parent segments).
typedef AuthorSmartMatchPathSources = ({
  String filenameStem,
  List<String> parentDirectorySegments,
});

/// Ranks Named facet form candidates: smart matches first, then attachment count.
///
/// Does not invent dictionary-external names. When [enabled] is false, order
/// follows [candidates] as given (already attachment-count sorted by core) and
/// no row is marked smartMatched.
///
/// Within the smartMatched group, sorts by [matchedSourceCounts] descending,
/// then attachment count descending, then name ascending.
List<SmartFacetMatchCandidate> applySmartFacetMatch({
  required List<NamedFacetFormCandidate> candidates,
  required Map<String, int> matchedSourceCounts,
  required bool enabled,
}) {
  if (!enabled || matchedSourceCounts.isEmpty) {
    return <SmartFacetMatchCandidate>[
      for (final NamedFacetFormCandidate c in candidates)
        (name: c.name, attachmentCount: c.attachmentCount, smartMatched: false),
    ];
  }

  final Map<String, int> hits = Map<String, int>.from(matchedSourceCounts)
    ..removeWhere((String _, int count) => count <= 0);
  if (hits.isEmpty) {
    return <SmartFacetMatchCandidate>[
      for (final NamedFacetFormCandidate c in candidates)
        (name: c.name, attachmentCount: c.attachmentCount, smartMatched: false),
    ];
  }

  final List<NamedFacetFormCandidate> matched = <NamedFacetFormCandidate>[];
  final List<NamedFacetFormCandidate> rest = <NamedFacetFormCandidate>[];
  for (final NamedFacetFormCandidate c in candidates) {
    if (hits.containsKey(c.name)) {
      matched.add(c);
    } else {
      rest.add(c);
    }
  }

  int bySourceCountThenAttachmentThenName(
    NamedFacetFormCandidate a,
    NamedFacetFormCandidate b,
  ) {
    final int bySource = hits[b.name]!.compareTo(hits[a.name]!);
    if (bySource != 0) {
      return bySource;
    }
    final int byCount = b.attachmentCount.compareTo(a.attachmentCount);
    if (byCount != 0) {
      return byCount;
    }
    return a.name.compareTo(b.name);
  }

  matched.sort(bySourceCountThenAttachmentThenName);
  // `rest` keeps core order (attachment DESC, name ASC).

  return <SmartFacetMatchCandidate>[
    for (final NamedFacetFormCandidate c in matched)
      (name: c.name, attachmentCount: c.attachmentCount, smartMatched: true),
    for (final NamedFacetFormCandidate c in rest)
      (name: c.name, attachmentCount: c.attachmentCount, smartMatched: false),
  ];
}

/// Author dictionary names with independent title / filename / parent-dir hits.
///
/// Returns name → source count (1–3). Names with zero hits are omitted.
Map<String, int> authorSmartMatchNames({
  required List<NamedFacetFormCandidate> dictionary,
  required String title,
  required String filenameStem,
  required List<String> parentDirectorySegments,
}) {
  final String titleHaystack = title.toLowerCase();
  final String filenameHaystack = filenameStem.toLowerCase();
  final bool titleEqualsFilename =
      titleHaystack.trim() == filenameHaystack.trim();
  final List<String> parentHaystacks = parentDirectorySegments
      .map((String segment) => segment.toLowerCase())
      .toList(growable: false);

  final Map<String, int> out = <String, int>{};
  for (final NamedFacetFormCandidate c in dictionary) {
    if (!_authorNameEligibleForSubstringMatch(c.name)) {
      continue;
    }
    final String needle = c.name.toLowerCase();
    int sourceCount = 0;

    final bool titleHit = titleHaystack.contains(needle);
    final bool filenameHit = filenameHaystack.contains(needle);
    if (titleHit || filenameHit) {
      if (titleEqualsFilename) {
        sourceCount += 1;
      } else {
        if (titleHit) {
          sourceCount += 1;
        }
        if (filenameHit) {
          sourceCount += 1;
        }
      }
    }

    final bool parentHit = parentHaystacks.any(
      (String haystack) => haystack.contains(needle),
    );
    if (parentHit) {
      sourceCount += 1;
    }

    if (sourceCount > 0) {
      out[c.name] = sourceCount;
    }
  }
  return out;
}

/// Resolves Author path signals from resource and optional relative library path.
///
/// When [relativeUnderLibraryRoot] is set, it drives filename stem and parent
/// segments. When [libraryRootKnown] is false, [resourcePath] is used as
/// fallback (basename + parent dirs). When the root is known but the resource
/// is outside it, only the resource basename is used (no parent segments).
AuthorSmartMatchPathSources resolveAuthorSmartMatchPathSources({
  required String resourcePath,
  required String? relativeUnderLibraryRoot,
  required bool libraryRootKnown,
}) {
  final String pathInput =
      relativeUnderLibraryRoot ??
      (libraryRootKnown ? _resourceBasename(resourcePath) : resourcePath);
  return authorSmartMatchPathSources(relativeResourcePath: pathInput);
}

/// Splits [relativeResourcePath] into filename stem and parent directory segments.
AuthorSmartMatchPathSources authorSmartMatchPathSources({
  required String relativeResourcePath,
}) {
  final String normalized = relativeResourcePath.replaceAll('\\', '/');
  final int lastSlash = normalized.lastIndexOf('/');
  final String basename;
  final List<String> segments;
  if (lastSlash < 0) {
    basename = normalized;
    segments = const <String>[];
  } else {
    basename = normalized.substring(lastSlash + 1);
    final String dir = normalized.substring(0, lastSlash);
    segments = dir.isEmpty
        ? const <String>[]
        : dir.split('/').where((String s) => s.isNotEmpty).toList();
  }
  return (
    filenameStem: _stripFileExtension(basename),
    parentDirectorySegments: segments,
  );
}

/// Tag / Parody / Character dictionary names present on Folder series siblings.
Set<String> siblingSmartMatchNames({
  required List<NamedFacetFormCandidate> dictionary,
  required Set<String> siblingAttachedNames,
  required bool isLibraryRootSeries,
}) {
  if (isLibraryRootSeries || siblingAttachedNames.isEmpty) {
    return <String>{};
  }
  final Set<String> dict = <String>{
    for (final NamedFacetFormCandidate c in dictionary) c.name,
  };
  return siblingAttachedNames.intersection(dict);
}

/// Resource path relative to [libraryRoot], or null if not under the root.
String? relativeResourcePathUnderRoot({
  required String resourcePath,
  required String libraryRoot,
}) {
  final String path = _trimTrailingSeparators(resourcePath);
  final String root = _trimTrailingSeparators(libraryRoot);
  if (root.isEmpty || path.isEmpty) {
    return null;
  }

  final bool ignoreCase =
      _looksLikeWindowsPath(path) || _looksLikeWindowsPath(root);
  final bool underRoot = ignoreCase
      ? path.toLowerCase().startsWith(root.toLowerCase())
      : path.startsWith(root);
  if (!underRoot) {
    return null;
  }
  if (path.length == root.length) {
    return '';
  }
  final String sep = path[root.length];
  if (sep != '/' && sep != '\\') {
    // Prefix match but not a path boundary (e.g. root `/a` vs path `/ab`).
    return null;
  }
  return path.substring(root.length + 1);
}

String _resourceBasename(String path) {
  final String normalized = path.replaceAll('\\', '/');
  final int slash = normalized.lastIndexOf('/');
  if (slash < 0 || slash >= normalized.length - 1) {
    return path;
  }
  return normalized.substring(slash + 1);
}

String _stripFileExtension(String basename) {
  final int dot = basename.lastIndexOf('.');
  if (dot <= 0) {
    return basename;
  }
  return basename.substring(0, dot);
}

bool _authorNameEligibleForSubstringMatch(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (_containsIdeographic(trimmed)) {
    return true;
  }
  return trimmed.runes.length >= 2;
}

bool _containsIdeographic(String value) {
  for (final int unit in value.runes) {
    if (_isIdeographicRune(unit)) {
      return true;
    }
  }
  return false;
}

bool _isIdeographicRune(int unit) {
  // CJK Unified Ideographs + common extensions + Hiragana/Katakana/Hangul.
  return (unit >= 0x3400 && unit <= 0x9FFF) ||
      (unit >= 0xF900 && unit <= 0xFAFF) ||
      (unit >= 0x3040 && unit <= 0x30FF) ||
      (unit >= 0xAC00 && unit <= 0xD7AF);
}

bool _looksLikeWindowsPath(String path) {
  if (path.length >= 2 && path[1] == ':') {
    return true;
  }
  return path.contains('\\');
}

/// Whether [seriesFolderPath] is the Library root series for [libraryRoot].
bool isLibraryRootSeriesFolder({
  required String? seriesFolderPath,
  required String? libraryRoot,
}) {
  if (seriesFolderPath == null || libraryRoot == null) {
    return false;
  }
  final String folder = _trimTrailingSeparators(seriesFolderPath);
  final String root = _trimTrailingSeparators(libraryRoot);
  if (folder.isEmpty || root.isEmpty) {
    return false;
  }
  if (_looksLikeWindowsPath(folder) || _looksLikeWindowsPath(root)) {
    return folder.toLowerCase() == root.toLowerCase();
  }
  return folder == root;
}

/// Longest Library root under which [resourcePath] lives, if any.
String? resolveLibraryRootForResourcePath({
  required String resourcePath,
  required Iterable<String> libraryRoots,
}) {
  String? best;
  int bestLen = -1;
  for (final String root in libraryRoots) {
    final String? relative = relativeResourcePathUnderRoot(
      resourcePath: resourcePath,
      libraryRoot: root,
    );
    if (relative == null) {
      continue;
    }
    final int len = _trimTrailingSeparators(root).length;
    if (len > bestLen) {
      bestLen = len;
      best = root;
    }
  }
  return best;
}

String _trimTrailingSeparators(String path) {
  String out = path.trim();
  while (out.endsWith('/') || out.endsWith('\\')) {
    out = out.substring(0, out.length - 1);
  }
  return out;
}
