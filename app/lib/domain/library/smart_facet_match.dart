import 'package:hentai_library/domain/models/named_facet_form_candidate.dart';

/// Comic metadata form candidate after Smart facet match ranking.
typedef SmartFacetMatchCandidate = ({
  String name,
  int attachmentCount,
  bool smartMatched,
});

/// Ranks Named facet form candidates: smart matches first, then attachment count.
///
/// Does not invent dictionary-external names. When [enabled] is false, order
/// follows [candidates] as given (already attachment-count sorted by core) and
/// no row is marked smartMatched.
List<SmartFacetMatchCandidate> applySmartFacetMatch({
  required List<NamedFacetFormCandidate> candidates,
  required Set<String> matchedNames,
  required bool enabled,
}) {
  if (!enabled || matchedNames.isEmpty) {
    return <SmartFacetMatchCandidate>[
      for (final NamedFacetFormCandidate c in candidates)
        (name: c.name, attachmentCount: c.attachmentCount, smartMatched: false),
    ];
  }

  final Set<String> hits = matchedNames.toSet();
  final List<NamedFacetFormCandidate> matched = <NamedFacetFormCandidate>[];
  final List<NamedFacetFormCandidate> rest = <NamedFacetFormCandidate>[];
  for (final NamedFacetFormCandidate c in candidates) {
    if (hits.contains(c.name)) {
      matched.add(c);
    } else {
      rest.add(c);
    }
  }

  int byAttachmentThenName(
    NamedFacetFormCandidate a,
    NamedFacetFormCandidate b,
  ) {
    final int byCount = b.attachmentCount.compareTo(a.attachmentCount);
    if (byCount != 0) {
      return byCount;
    }
    return a.name.compareTo(b.name);
  }

  matched.sort(byAttachmentThenName);
  // `rest` keeps core order (attachment DESC, name ASC).

  return <SmartFacetMatchCandidate>[
    for (final NamedFacetFormCandidate c in matched)
      (name: c.name, attachmentCount: c.attachmentCount, smartMatched: true),
    for (final NamedFacetFormCandidate c in rest)
      (name: c.name, attachmentCount: c.attachmentCount, smartMatched: false),
  ];
}

/// Author dictionary names that substring-match title or relative resource path.
Set<String> authorSmartMatchNames({
  required List<NamedFacetFormCandidate> dictionary,
  required String title,
  required String relativeResourcePath,
}) {
  final String haystack = '$title\n$relativeResourcePath'.toLowerCase();
  final Set<String> out = <String>{};
  for (final NamedFacetFormCandidate c in dictionary) {
    if (!_authorNameEligibleForSubstringMatch(c.name)) {
      continue;
    }
    if (haystack.contains(c.name.toLowerCase())) {
      out.add(c.name);
    }
  }
  return out;
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
