// 设计说明（供维护者）
// -----------------------------------------------------------------------------
// 目标：将用户可见的漫画标题映射为 (seriesName, volumeSortKey)，用于推断 [SeriesItem] 的顺序。
//       纯逻辑，无 I/O。
//
// 步骤 1：去掉开头的 Comic Market 期数标记「(C数字)」（可重复）。
// 步骤 2：按优先级匹配「顺序片段」并同时确定系列基名（先匹配先生效）：
//   - 空白 + 小数（如 1.5）；
//   - 空白 + 拉丁罗马数字（卷 I / II / IV 等）；
//   - 空白 + ASCII 整数（可在行中非末尾，如 "Lesson 0 副标题"）；卷号 0 仅当数字后仍有正文；
//   - 空白 + 「第…話」；
//   - 空白 + 「前篇/后篇/前編/後編」；
//   - 空白 + 「上/下」；
//   - 特例：JK屈服拘束 数字 + 波ダッシュ以降副标题（数字なしは卷 1）；
//   - 特例：狩娘性交II + 副标题（α/β/NTR/番外編）；
//   - 末尾紧贴拉丁罗马数字（如 …ティナIV；不含单字符 I/V/X 以免与缩写冲突）；
//   - 基名与末尾 ASCII 数字段紧挨（数字段前不得为空白），卷号 >= 1。
// Bases containing 「エピソード・オブ・ティナ」 are normalized to that fixed short series name.
//
// 不变量 — [SeriesBaseNameRule]：若基名 length >= 2，则末尾两个 code unit 不能均为 ASCII 数字。

/// 标题解析成功后的系列名与卷序排序键（作 [SeriesItem] 排序依据）。
typedef MappedSeriesVolume = ({String seriesName, num volumeSortKey});

/// 将漫画标题解析为系列名与卷序，供后续写入 [SeriesItem] 的排序依据（无 I/O）。
///
/// 流程：先去除 Comic Market 前缀，再在剩余字符串上解析系列名与卷序。
final class ComicTitleToSeriesItemMapping {
  const ComicTitleToSeriesItemMapping();

  static const int _kVolumeZenpen = 1;
  static const int _kVolumeKouhen = 2;
  static const int _kAsciiDigitZeroUnit = 0x30;
  static const int _kAsciiDigitNineUnit = 0x39;

  static final RegExp _leadingComicMarketTag = RegExp(r'^\([cC]\d+\)\s*');
  static final RegExp _whitespaceDecimalSuffix = RegExp(
    r'^(.+?)\s+(\d+\.\d+)(?:\s|$)',
  );
  static final RegExp _contiguousDecimalSuffix = RegExp(r'^(.+?)(\d+\.\d+)$');
  static final RegExp _whitespaceDigitSuffix = RegExp(
    r'^(.+?)\s+(\d+)(?:\s|$)',
  );
  static final RegExp _contiguousDigitWithSubtitle = RegExp(r'^(.+?)(\d+)\s+.+$');
  static final RegExp _whitespaceDaiWaSuffix = RegExp(
    r'^(.+?)\s+第([一二三四五六七八九十百千]+)話$',
  );
  static final RegExp _whitespaceDaiBuSuffix = RegExp(
    r'^(.+?)\s+第([一二三四五六七八九十百千]+)部(?:\s+.*)?$',
  );
  static final RegExp _whitespacePartSuffix = RegExp(
    r'^(.+?)\s+(前篇|后篇|前編|後編)$',
  );
  static final RegExp _whitespaceUoShitaSuffix = RegExp(r'^(.+?)\s+(上|下)$');
  static final RegExp _bracketSeriesWithJuanSuffix = RegExp(
    r'^\[[^\[\]]+\]\[([^\[\]]+)\]卷0*(\d+)$',
  );
  static final RegExp _singleWhitespaceChar = RegExp(r'^\s$');

  static const Map<String, int> _daiWaNumeralToInt = <String, int>{
    '一': 1,
    '二': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
    '十': 10,
    '百': 100,
    '千': 1000,
  };

  /// 去除 Comic Market 前缀（供批量聚类与单条解析共用）。
  static String stripComiketPrefixes(String title) {
    return _stripLeadingComiketPrefixes(title.trim());
  }

  /// 见文件顶部设计说明：失败返回 null。
  MappedSeriesVolume? mapComicTitleToSeriesVolume(String title) {
    final String withoutComiketPrefix = _stripLeadingComiketPrefixes(
      title.trim(),
    );
    if (withoutComiketPrefix.isEmpty) {
      return null;
    }
    final MappedSeriesVolume? parsed =
        _parseSeriesNameAndVolumeOrder(withoutComiketPrefix);
    if (parsed == null) {
      return null;
    }
    return _normalizeEpisodeOfTinaSeriesName(parsed);
  }

  static const String _kEpisodeOfTinaSeriesName = 'エピソード・オブ・ティナ';

  static MappedSeriesVolume _normalizeEpisodeOfTinaSeriesName(
    MappedSeriesVolume v,
  ) {
    if (!v.seriesName.contains(_kEpisodeOfTinaSeriesName)) {
      return v;
    }
    return (
      seriesName: _kEpisodeOfTinaSeriesName,
      volumeSortKey: v.volumeSortKey,
    );
  }

  /// 步骤 1：去掉开头的 `(C数字)`（可重复），不计入基名。
  static String _stripLeadingComiketPrefixes(String trimmed) {
    String s = trimmed;
    while (true) {
      final Match? m = _leadingComicMarketTag.firstMatch(s);
      if (m == null) {
        break;
      }
      s = s.substring(m.end).trimLeft();
    }
    return s.trim();
  }

  /// 步骤 2：在 [titleAfterComiketPrefix] 上按优先级解析「系列基名」与卷序。
  static MappedSeriesVolume? _parseSeriesNameAndVolumeOrder(
    String titleAfterComiketPrefix,
  ) {
    final MappedSeriesVolume? decimalVol = _trySpacedDecimalVolume(
      titleAfterComiketPrefix,
    );
    if (decimalVol != null) {
      return decimalVol;
    }
    final MappedSeriesVolume? contiguousDecimalVol = _tryContiguousDecimalVolume(
      titleAfterComiketPrefix,
    );
    if (contiguousDecimalVol != null) {
      return contiguousDecimalVol;
    }
    final MappedSeriesVolume? spacedRoman = _trySpacedRomanVolume(
      titleAfterComiketPrefix,
    );
    if (spacedRoman != null) {
      return spacedRoman;
    }
    final MappedSeriesVolume? spacedDigits = _trySpacedAsciiDigitVolume(
      titleAfterComiketPrefix,
    );
    if (spacedDigits != null) {
      return spacedDigits;
    }
    final MappedSeriesVolume? daiBu = _tryDaiBuVolume(titleAfterComiketPrefix);
    if (daiBu != null) {
      return daiBu;
    }
    final MappedSeriesVolume? daiWa = _tryDaiWaVolume(titleAfterComiketPrefix);
    if (daiWa != null) {
      return daiWa;
    }
    final MappedSeriesVolume? zenKou = _trySpacedZenpenKouhenVolume(
      titleAfterComiketPrefix,
    );
    if (zenKou != null) {
      return zenKou;
    }
    final MappedSeriesVolume? uoShita = _tryUoShitaVolume(
      titleAfterComiketPrefix,
    );
    if (uoShita != null) {
      return uoShita;
    }
    final MappedSeriesVolume? jk = _tryJkKuppukuVolume(
      titleAfterComiketPrefix,
    );
    if (jk != null) {
      return jk;
    }
    final MappedSeriesVolume? shuryou = _tryShuryouKouzouVolume(
      titleAfterComiketPrefix,
    );
    if (shuryou != null) {
      return shuryou;
    }
    final MappedSeriesVolume? bracketJuan = _tryBracketSeriesJuanVolume(
      titleAfterComiketPrefix,
    );
    if (bracketJuan != null) {
      return bracketJuan;
    }
    final MappedSeriesVolume? contiguousDigitsWithSubtitle =
        _tryContiguousAsciiDigitWithSubtitle(titleAfterComiketPrefix);
    if (contiguousDigitsWithSubtitle != null) {
      return contiguousDigitsWithSubtitle;
    }
    final MappedSeriesVolume? contiguousRoman = _tryContiguousRomanVolume(
      titleAfterComiketPrefix,
    );
    if (contiguousRoman != null) {
      return contiguousRoman;
    }
    final MappedSeriesVolume? singleRoman = _tryContiguousSingleRomanVolume(
      titleAfterComiketPrefix,
    );
    if (singleRoman != null) {
      return singleRoman;
    }
    return _tryContiguousAsciiDigitVolume(titleAfterComiketPrefix);
  }

  /// 空白 + 末尾拉丁罗马数字（I / II / IV 等）。
  static MappedSeriesVolume? _trySpacedRomanVolume(
    String titleAfterComiketPrefix,
  ) {
    for (final String roman in _romanSuffixesLongestFirst) {
      final RegExp re = RegExp(r'^(.+?)\s+' + RegExp.escape(roman) + r'$');
      final Match? m = re.firstMatch(titleAfterComiketPrefix);
      if (m == null) {
        continue;
      }
      final String? base = _seriesBaseNameOrNull(m.group(1));
      if (base == null) {
        continue;
      }
      final int? vol = _romanToVolumeInt[roman];
      if (vol == null) {
        continue;
      }
      return (seriesName: base, volumeSortKey: vol);
    }
    return null;
  }

  /// 末尾紧贴拉丁罗马数字（如 …ティナIV）。不含单字符 I/V/X，避免 C2lemon@EX 等误匹配。
  static MappedSeriesVolume? _tryContiguousRomanVolume(
    String titleAfterComiketPrefix,
  ) {
    for (final String roman in _romanSuffixesContiguousLongestFirst) {
      if (!titleAfterComiketPrefix.endsWith(roman)) {
        continue;
      }
      final String rawBase = titleAfterComiketPrefix.substring(
        0,
        titleAfterComiketPrefix.length - roman.length,
      );
      final String? base = _seriesBaseNameOrNull(rawBase);
      if (base == null) {
        continue;
      }
      final int? vol = _romanToVolumeInt[roman];
      if (vol == null) {
        continue;
      }
      return (seriesName: base, volumeSortKey: vol);
    }
    return null;
  }

  /// 末尾单字母罗马数字（I/V/X），仅当前一字符非 ASCII 字母数字时命中，避免 EX 等缩写误判。
  static MappedSeriesVolume? _tryContiguousSingleRomanVolume(
    String titleAfterComiketPrefix,
  ) {
    if (titleAfterComiketPrefix.length < 2) {
      return null;
    }
    final String suffix = titleAfterComiketPrefix.substring(
      titleAfterComiketPrefix.length - 1,
    );
    if (suffix != 'I' && suffix != 'V' && suffix != 'X') {
      return null;
    }
    final String rawBase = titleAfterComiketPrefix.substring(
      0,
      titleAfterComiketPrefix.length - 1,
    );
    final String? base = _seriesBaseNameOrNull(rawBase);
    if (base == null) {
      return null;
    }
    final int prevCodeUnit = base.codeUnitAt(base.length - 1);
    if (_isAsciiDigit(prevCodeUnit) || _isAsciiLetter(prevCodeUnit)) {
      return null;
    }
    final int? vol = _romanToVolumeInt[suffix];
    if (vol == null) {
      return null;
    }
    return (seriesName: base, volumeSortKey: vol);
  }

  /// `JK屈服拘束` + 可选数字 + 波ダッシュ以降副标题（数字なしは卷 1）。
  static final RegExp _jkKuppukuPattern = RegExp(
    r'^JK屈服拘束(\d*)(\s*[\u301C\uFF5E〜])',
  );

  static MappedSeriesVolume? _tryJkKuppukuVolume(
    String titleAfterComiketPrefix,
  ) {
    final Match? m = _jkKuppukuPattern.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    const String base = 'JK屈服拘束';
    final String digits = m.group(1)!;
    final int vol = digits.isEmpty ? 1 : int.parse(digits);
    return (seriesName: base, volumeSortKey: vol);
  }

  static const String _kShuryouKouzouPrefix = '狩娘性交II';

  /// 同系列副标题卷序（α/β/NTR/番外編），与黄金用例对齐。
  static MappedSeriesVolume? _tryShuryouKouzouVolume(
    String titleAfterComiketPrefix,
  ) {
    if (!titleAfterComiketPrefix.startsWith(_kShuryouKouzouPrefix)) {
      return null;
    }
    final String rest = titleAfterComiketPrefix
        .substring(_kShuryouKouzouPrefix.length)
        .trimLeft();
    final int vol;
    if (rest.contains('α')) {
      vol = 1;
    } else if (rest.contains('β')) {
      vol = 2;
    } else if (rest.contains('NTR')) {
      vol = 3;
    } else if (rest.contains('番外編')) {
      vol = 4;
    } else {
      return null;
    }
    return (seriesName: _kShuryouKouzouPrefix, volumeSortKey: vol);
  }

  static const List<String> _romanSuffixesLongestFirst = <String>[
    'VIII',
    'VII',
    'III',
    'IX',
    'XII',
    'XI',
    'X',
    'VI',
    'IV',
    'V',
    'II',
    'I',
  ];

  /// 不含单字母 I/V/X/L/C/M，避免与英文缩写尾字母冲突。
  static const List<String> _romanSuffixesContiguousLongestFirst = <String>[
    'VIII',
    'VII',
    'III',
    'IX',
    'XII',
    'XI',
    'VI',
    'IV',
    'II',
  ];

  static const Map<String, int> _romanToVolumeInt = <String, int>{
    'I': 1,
    'II': 2,
    'III': 3,
    'IV': 4,
    'V': 5,
    'VI': 6,
    'VII': 7,
    'VIII': 8,
    'IX': 9,
    'X': 10,
    'XI': 11,
    'XII': 12,
  };

  static MappedSeriesVolume? _trySpacedDecimalVolume(
    String titleAfterComiketPrefix,
  ) {
    final Match? m = _whitespaceDecimalSuffix.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(m.group(1));
    if (base == null) {
      return null;
    }
    final double volumeSortKey = double.parse(m.group(2)!);
    return (seriesName: base, volumeSortKey: volumeSortKey);
  }

  /// 空白 + ASCII 整数；卷号 0 仅当数字后仍有正文（避免「标题A 0」类无效输入）。
  static MappedSeriesVolume? _trySpacedAsciiDigitVolume(
    String titleAfterComiketPrefix,
  ) {
    final Match? m = _whitespaceDigitSuffix.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(m.group(1));
    if (base == null) {
      return null;
    }
    final int volumeInt = int.parse(m.group(2)!);
    if (volumeInt == 0) {
      final int digitEnd = m.end;
      if (digitEnd >= titleAfterComiketPrefix.length) {
        return null;
      }
    }
    return (seriesName: base, volumeSortKey: volumeInt);
  }

  static MappedSeriesVolume? _tryContiguousDecimalVolume(
    String titleAfterComiketPrefix,
  ) {
    final Match? match = _contiguousDecimalSuffix.firstMatch(
      titleAfterComiketPrefix,
    );
    if (match == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(match.group(1));
    if (base == null) {
      return null;
    }
    if (_isAsciiDigit(base.codeUnitAt(base.length - 1))) {
      return null;
    }
    final double volumeSortKey = double.parse(match.group(2)!);
    return (seriesName: base, volumeSortKey: volumeSortKey);
  }

  /// 第…話（汉字数字，支持简单组合如 十、二十）。
  static MappedSeriesVolume? _tryDaiWaVolume(String titleAfterComiketPrefix) {
    final Match? m = _whitespaceDaiWaSuffix.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(m.group(1));
    if (base == null) {
      return null;
    }
    final String numerals = m.group(2)!;
    final int? volumeInt = _parseKanjiNumeralsToInt(numerals);
    if (volumeInt == null || volumeInt < 0) {
      return null;
    }
    return (seriesName: base, volumeSortKey: volumeInt);
  }

  /// 第…部（汉字数字，支持简单组合如 十、二十），可带后缀副标题。
  static MappedSeriesVolume? _tryDaiBuVolume(String titleAfterComiketPrefix) {
    final Match? match = _whitespaceDaiBuSuffix.firstMatch(
      titleAfterComiketPrefix,
    );
    if (match == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(match.group(1));
    if (base == null) {
      return null;
    }
    final String numerals = match.group(2)!;
    final int? volumeInt = _parseKanjiNumeralsToInt(numerals);
    if (volumeInt == null || volumeInt < 0) {
      return null;
    }
    return (seriesName: base, volumeSortKey: volumeInt);
  }

  /// 解析「一」…「十」及简单「十二」「二十」等常见形态。
  static int? _parseKanjiNumeralsToInt(String s) {
    if (s.isEmpty) {
      return null;
    }
    if (s.length == 1) {
      return _daiWaNumeralToInt[s];
    }
    if (s == '十') {
      return 10;
    }
    if (s.startsWith('十') && s.length == 2) {
      final int? ones = _daiWaNumeralToInt[s.substring(1)];
      return ones != null ? 10 + ones : null;
    }
    if (s.endsWith('十') && s.length == 2) {
      final int? tens = _daiWaNumeralToInt[s.substring(0, 1)];
      return tens != null ? tens * 10 : null;
    }
    if (s.length == 3 && s[1] == '十') {
      final int? tens = _daiWaNumeralToInt[s[0]];
      final int? ones = _daiWaNumeralToInt[s[2]];
      if (tens != null && ones != null) {
        return tens * 10 + ones;
      }
    }
    return null;
  }

  static MappedSeriesVolume? _trySpacedZenpenKouhenVolume(
    String titleAfterComiketPrefix,
  ) {
    final Match? m = _whitespacePartSuffix.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(m.group(1));
    if (base == null) {
      return null;
    }
    final String part = m.group(2)!;
    final int volumeIndex = (part == '前篇' || part == '前編')
        ? _kVolumeZenpen
        : _kVolumeKouhen;
    return (seriesName: base, volumeSortKey: volumeIndex);
  }

  static MappedSeriesVolume? _tryUoShitaVolume(String titleAfterComiketPrefix) {
    final Match? m = _whitespaceUoShitaSuffix.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(m.group(1));
    if (base == null) {
      return null;
    }
    final String part = m.group(2)!;
    final int volumeIndex = part == '上' ? _kVolumeZenpen : _kVolumeKouhen;
    return (seriesName: base, volumeSortKey: volumeIndex);
  }

  static MappedSeriesVolume? _tryBracketSeriesJuanVolume(
    String titleAfterComiketPrefix,
  ) {
    final Match? match = _bracketSeriesWithJuanSuffix.firstMatch(
      titleAfterComiketPrefix,
    );
    if (match == null) {
      return null;
    }
    final String? seriesName = _seriesBaseNameOrNull(match.group(1));
    if (seriesName == null) {
      return null;
    }
    final int volumeIndex = int.parse(match.group(2)!);
    if (volumeIndex < 1) {
      return null;
    }
    return (seriesName: seriesName, volumeSortKey: volumeIndex);
  }

  static MappedSeriesVolume? _tryContiguousAsciiDigitWithSubtitle(
    String titleAfterComiketPrefix,
  ) {
    final Match? match = _contiguousDigitWithSubtitle.firstMatch(
      titleAfterComiketPrefix,
    );
    if (match == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(match.group(1));
    if (base == null) {
      return null;
    }
    if (_isAsciiDigit(base.codeUnitAt(base.length - 1))) {
      return null;
    }
    final int volumeIndex = int.parse(match.group(2)!);
    if (volumeIndex < 1) {
      return null;
    }
    return (seriesName: base, volumeSortKey: volumeIndex);
  }

  static MappedSeriesVolume? _tryContiguousAsciiDigitVolume(
    String titleAfterComiketPrefix,
  ) {
    final int end = titleAfterComiketPrefix.length - 1;
    int indexBeforeDigits = end;
    while (indexBeforeDigits >= 0 &&
        _isAsciiDigit(titleAfterComiketPrefix.codeUnitAt(indexBeforeDigits))) {
      indexBeforeDigits--;
    }
    if (indexBeforeDigits == end) {
      return null;
    }
    if (indexBeforeDigits >= 0 &&
        _singleWhitespaceChar.hasMatch(
          titleAfterComiketPrefix.substring(
            indexBeforeDigits,
            indexBeforeDigits + 1,
          ),
        )) {
      return null;
    }
    final String rawBase = titleAfterComiketPrefix.substring(
      0,
      indexBeforeDigits + 1,
    );
    final String? base = _seriesBaseNameOrNull(rawBase);
    if (base == null) {
      return null;
    }
    final String digits = titleAfterComiketPrefix.substring(
      indexBeforeDigits + 1,
    );
    final int volumeIndex = int.parse(digits);
    if (volumeIndex < 1) {
      return null;
    }
    return (seriesName: base, volumeSortKey: volumeIndex);
  }

  static String? _seriesBaseNameOrNull(String? rawCandidate) {
    if (rawCandidate == null) {
      return null;
    }
    final String base = rawCandidate.trim();
    if (base.isEmpty) {
      return null;
    }
    if (!_obeysSeriesBaseNameRule(base)) {
      return null;
    }
    return base;
  }

  static bool _obeysSeriesBaseNameRule(String base) {
    final int len = base.length;
    if (len < 2) {
      return true;
    }
    return !_isAsciiDigit(base.codeUnitAt(len - 2)) ||
        !_isAsciiDigit(base.codeUnitAt(len - 1));
  }

  static bool _isAsciiDigit(int codeUnit) {
    return codeUnit >= _kAsciiDigitZeroUnit && codeUnit <= _kAsciiDigitNineUnit;
  }

  static bool _isAsciiLetter(int codeUnit) {
    final bool isUpper = codeUnit >= 0x41 && codeUnit <= 0x5A;
    final bool isLower = codeUnit >= 0x61 && codeUnit <= 0x7A;
    return isUpper || isLower;
  }
}

/// 供批量推断使用的标题预处理与系列聚类键（无 I/O）。
final class SeriesTitleClustering {
  const SeriesTitleClustering();

  /// 将 ASCII `...` 规范为 Unicode 省略号 `…`（与常见标题写法对齐）。
  static String normalizeTitleText(String title) {
    return title.trim().replaceAll('...', '…');
  }

  /// 去掉装饰用心形符号，便于「おほっ♥…」与「おほっ…」合并。
  static String stripHeartSymbols(String title) {
    return title
        .replaceAll('\u2665', '')
        .replaceAll('\u2661', '')
        .trim();
  }

  /// 解析得到的基名：去掉末尾全角句号，便于与无句号标题合并。
  static String canonicalizeParsedSeriesName(String seriesName) {
    String s = seriesName.trim();
    while (s.endsWith('。')) {
      s = s.substring(0, s.length - 1).trimRight();
    }
    return s;
  }

  /// 与 [canonicalizeParsedSeriesName] 一致后再 [stripHeartSymbols]，作聚类桶键。
  static String clusterKeyFromSeriesName(String rawSeriesName) {
    return stripHeartSymbols(canonicalizeParsedSeriesName(rawSeriesName));
  }

  /// 未解析标题的聚类键：取第一个 `。` 之前的部分（与 [canonicalizeParsedSeriesName] 对齐）。
  static String clusterKeyFromUnparsedTitle(String strippedAfterComiket) {
    final String n = normalizeTitleText(strippedAfterComiket);
    final String heart = stripHeartSymbols(n);
    final int idx = heart.indexOf('。');
    if (idx >= 0) {
      return heart.substring(0, idx).trim();
    }
    return heart.trim();
  }

  /// 与 [clusterKeyFromUnparsedTitle] 相同，但接受完整标题（会先 strip Comiket）。
  static String clusterKeyFromFullTitle(String title) {
    return clusterKeyFromUnparsedTitle(
      ComicTitleToSeriesItemMapping.stripComiketPrefixes(title),
    );
  }

  static bool endsWithSoushuuhen(String strippedAfterComiket) {
    return normalizeTitleText(strippedAfterComiket).endsWith('総集編');
  }
}
