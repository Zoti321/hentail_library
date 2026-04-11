// 设计说明（供维护者）
// -----------------------------------------------------------------------------
// 目标：将用户可见的漫画标题映射为 (seriesName, volumeIndex)，用于推断 [SeriesItem] 的顺序。
//       纯逻辑，无 I/O。
//
// 逻辑流程（概念上可概括为三步；实现上「基名」与「顺序」在每条规则里一并得出）：
//   1) 去除前缀：去掉开头的 Comic Market 期数标记「(C数字)」（大小写 C，可连续多个），不计入基名。
//   2) 在剩余标题上找「代表顺序的片段」并同时确定「系列基名」——按下面三条规则依次尝试，先匹配先生效。
//   3) 三条规则（顺序片段的形态）：
//        a) 空白 + 末尾 ASCII 数字（卷号 >= 1）；
//        b) 空白 + 「前篇」|「后篇」→ 卷号 1 | 2；
//        c) 基名与末尾 ASCII 数字段紧挨（数字段前不得为空白）。
//
// 不变量 — [SeriesBaseNameRule]：若基名 length >= 2，则末尾两个 code unit 不能均为 ASCII 数字。
//         用于减少诸如将 "1234" 歧义拆成 "12" + "34" 之类的情况。

/// 单本漫画用于标题映射的输入。
final class ComicTitleInput {
  const ComicTitleInput({required this.comicId, required this.title});

  final String comicId;
  final String title;
}

/// 标题解析成功后的系列名与卷序（作 [SeriesItem] 排序键）。
final class MappedSeriesVolume {
  const MappedSeriesVolume({
    required this.seriesName,
    required this.volumeIndex,
  });

  final String seriesName;
  final int volumeIndex;
}

/// 将漫画标题解析为系列名与卷序，供后续写入 [SeriesItem] 的排序依据（无 I/O）。
///
/// 流程：先去除 Comic Market 前缀，再在剩余字符串上解析系列名与卷序。
final class ComicTitleToSeriesItemMapping {
  const ComicTitleToSeriesItemMapping();

  static const int _kMinVolumeIndex = 1;
  static const int _kVolumeZenpen = 1;
  static const int _kVolumeKouhen = 2;
  static const int _kAsciiDigitZeroUnit = 0x30;
  static const int _kAsciiDigitNineUnit = 0x39;

  static final RegExp _leadingComicMarketTag = RegExp(r'^\([cC]\d+\)\s*');
  static final RegExp _whitespaceDigitSuffix = RegExp(r'^(.+?)\s+(\d+)$');
  static final RegExp _whitespacePartSuffix = RegExp(r'^(.+?)\s+(前篇|后篇)$');
  static final RegExp _singleWhitespaceChar = RegExp(r'^\s$');

  /// 见文件顶部设计说明：失败返回 null。
  MappedSeriesVolume? mapComicTitleToSeriesVolume(String title) {
    final String trimmed = title.trim();
    final String titleAfterComiketPrefix = _removeLeadingComicMarketPrefixes(trimmed);
    if (titleAfterComiketPrefix.isEmpty) {
      return null;
    }
    return _parseSeriesNameAndVolumeOrder(titleAfterComiketPrefix);
  }

  /// 步骤 1：去掉开头的 `(C数字)`（可重复），不计入基名。
  static String _removeLeadingComicMarketPrefixes(String trimmed) {
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

  /// 步骤 2：在 [titleAfterComiketPrefix] 上按优先级解析「系列基名」与卷序（先匹配先生效）。
  static MappedSeriesVolume? _parseSeriesNameAndVolumeOrder(String titleAfterComiketPrefix) {
    final MappedSeriesVolume? spacedDigits =
        _trySpacedAsciiDigitVolume(titleAfterComiketPrefix);
    if (spacedDigits != null) {
      return spacedDigits;
    }
    final MappedSeriesVolume? zenKou =
        _trySpacedZenpenKouhenVolume(titleAfterComiketPrefix);
    if (zenKou != null) {
      return zenKou;
    }
    return _tryContiguousAsciiDigitVolume(titleAfterComiketPrefix);
  }

  /// 规则 a：基名 + 空白 + 末尾 ASCII 数字（卷号 >= 1）。
  static MappedSeriesVolume? _trySpacedAsciiDigitVolume(String titleAfterComiketPrefix) {
    final Match? m = _whitespaceDigitSuffix.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(m.group(1));
    if (base == null) {
      return null;
    }
    final int volumeIndex = int.parse(m.group(2)!);
    if (volumeIndex < _kMinVolumeIndex) {
      return null;
    }
    return MappedSeriesVolume(seriesName: base, volumeIndex: volumeIndex);
  }

  /// 规则 b：基名 + 空白 + 「前篇」|「后篇」→ 卷号 1 | 2。
  static MappedSeriesVolume? _trySpacedZenpenKouhenVolume(String titleAfterComiketPrefix) {
    final Match? m = _whitespacePartSuffix.firstMatch(titleAfterComiketPrefix);
    if (m == null) {
      return null;
    }
    final String? base = _seriesBaseNameOrNull(m.group(1));
    if (base == null) {
      return null;
    }
    final String part = m.group(2)!;
    final int volumeIndex = part == '前篇' ? _kVolumeZenpen : _kVolumeKouhen;
    return MappedSeriesVolume(seriesName: base, volumeIndex: volumeIndex);
  }

  /// 规则 c：基名与末尾 ASCII 数字段直接相连（数字段前一位不得为空白）。
  static MappedSeriesVolume? _tryContiguousAsciiDigitVolume(String titleAfterComiketPrefix) {
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
    final String rawBase = titleAfterComiketPrefix.substring(0, indexBeforeDigits + 1);
    final String? base = _seriesBaseNameOrNull(rawBase);
    if (base == null) {
      return null;
    }
    final String digits = titleAfterComiketPrefix.substring(indexBeforeDigits + 1);
    final int volumeIndex = int.parse(digits);
    if (volumeIndex < _kMinVolumeIndex) {
      return null;
    }
    return MappedSeriesVolume(seriesName: base, volumeIndex: volumeIndex);
  }

  /// 对候选基名做 trim；若为空或违反 [SeriesBaseNameRule] 则返回 null。
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

  /// [SeriesBaseNameRule]：长度 ≥2 时末尾两位不能均为 ASCII 数字。
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
}
