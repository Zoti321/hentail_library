use std::collections::HashMap;
use std::sync::LazyLock;

use regex::Regex;

use super::volume_key::VolumeSortKey;

/// 标题解析成功后的系列名与卷序排序键。
pub type MappedSeriesVolume = (String, VolumeSortKey);

const K_VOLUME_ZENPEN: i32 = 1;
const K_VOLUME_KOUHEN: i32 = 2;
const K_ASCII_DIGIT_ZERO: u32 = 0x30;
const K_ASCII_DIGIT_NINE: u32 = 0x39;
const K_EPISODE_OF_TINA_SERIES_NAME: &str = "エピソード・オブ・ティナ";
const K_SHURYOU_KOUZOU_PREFIX: &str = "狩娘性交II";

static LEADING_COMIC_MARKET_TAG: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^\([cC]\d+\)\s*").unwrap());
static WHITESPACE_DECIMAL_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)\s+(\d+\.\d+)(?:\s|$)").unwrap());
static CONTIGUOUS_DECIMAL_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)(\d+\.\d+)$").unwrap());
static WHITESPACE_DIGIT_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)\s+(\d+)(?:\s|$)").unwrap());
static CONTIGUOUS_DIGIT_WITH_SUBTITLE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)(\d+)\s+.+$").unwrap());
static WHITESPACE_DAI_WA_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)\s+第([一二三四五六七八九十百千]+)話$").unwrap());
static WHITESPACE_DAI_BU_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)\s+第([一二三四五六七八九十百千]+)部(?:\s+.*)?$").unwrap());
static WHITESPACE_PART_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)\s+(前篇|后篇|前編|後編)$").unwrap());
static WHITESPACE_UO_SHITA_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(.+?)\s+(上|下)$").unwrap());
static BRACKET_SERIES_WITH_JUAN_SUFFIX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^\[[^\[\]]+\]\[([^\[\]]+)\]卷0*(\d+)$").unwrap());
static JK_KUPPUKU_PATTERN: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^JK屈服拘束(\d*)(\s*[\u301C\uFF5E〜])").unwrap());

static ROMAN_SUFFIXES_LONGEST_FIRST: &[&str] = &[
    "VIII", "VII", "III", "IX", "XII", "XI", "X", "VI", "IV", "V", "II", "I",
];

static ROMAN_SUFFIXES_CONTIGUOUS_LONGEST_FIRST: &[&str] =
    &["VIII", "VII", "III", "IX", "XII", "XI", "VI", "IV", "II"];

fn roman_to_volume_int() -> &'static HashMap<&'static str, i32> {
    static MAP: LazyLock<HashMap<&'static str, i32>> = LazyLock::new(|| {
        HashMap::from([
            ("I", 1),
            ("II", 2),
            ("III", 3),
            ("IV", 4),
            ("V", 5),
            ("VI", 6),
            ("VII", 7),
            ("VIII", 8),
            ("IX", 9),
            ("X", 10),
            ("XI", 11),
            ("XII", 12),
        ])
    });
    &MAP
}

fn dai_wa_numeral_to_int() -> &'static HashMap<char, i32> {
    static MAP: LazyLock<HashMap<char, i32>> = LazyLock::new(|| {
        HashMap::from([
            ('一', 1),
            ('二', 2),
            ('三', 3),
            ('四', 4),
            ('五', 5),
            ('六', 6),
            ('七', 7),
            ('八', 8),
            ('九', 9),
            ('十', 10),
            ('百', 100),
            ('千', 1000),
        ])
    });
    &MAP
}

/// 将漫画标题解析为系列名与卷序，供后续写入 SeriesItem 的排序依据（无 I/O）。
#[derive(Debug, Clone, Copy, Default)]
pub struct ComicTitleToSeriesItemMapping;

impl ComicTitleToSeriesItemMapping {
    /// 去除 Comic Market 前缀（供批量聚类与单条解析共用）。
    pub fn strip_comiket_prefixes(title: &str) -> String {
        Self::strip_leading_comiket_prefixes(title.trim())
    }

    /// 见 Dart 设计说明：失败返回 None。
    pub fn map_comic_title_to_series_volume(&self, title: &str) -> Option<MappedSeriesVolume> {
        let without_comiket_prefix = Self::strip_leading_comiket_prefixes(title.trim());
        if without_comiket_prefix.is_empty() {
            return None;
        }
        let parsed = Self::parse_series_name_and_volume_order(&without_comiket_prefix)?;
        Some(Self::normalize_episode_of_tina_series_name(parsed))
    }

    fn normalize_episode_of_tina_series_name(v: MappedSeriesVolume) -> MappedSeriesVolume {
        if !v.0.contains(K_EPISODE_OF_TINA_SERIES_NAME) {
            return v;
        }
        (
            K_EPISODE_OF_TINA_SERIES_NAME.to_string(),
            v.1,
        )
    }

    fn strip_leading_comiket_prefixes(trimmed: &str) -> String {
        let mut s = trimmed.to_string();
        loop {
            let Some(m) = LEADING_COMIC_MARKET_TAG.find(&s) else {
                break;
            };
            s = s[m.end()..].trim_start().to_string();
        }
        s.trim().to_string()
    }

    fn parse_series_name_and_volume_order(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        if let Some(v) = Self::try_spaced_decimal_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_contiguous_decimal_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_spaced_roman_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_spaced_ascii_digit_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_dai_bu_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_dai_wa_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_spaced_zenpen_kouhen_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_uo_shita_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_jk_kuppuku_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_shuryou_kouzou_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_bracket_series_juan_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_contiguous_ascii_digit_with_subtitle(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_contiguous_roman_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        if let Some(v) = Self::try_contiguous_single_roman_volume(title_after_comiket_prefix) {
            return Some(v);
        }
        Self::try_contiguous_ascii_digit_volume(title_after_comiket_prefix)
    }

    fn try_spaced_roman_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let roman_map = roman_to_volume_int();
        for roman in ROMAN_SUFFIXES_LONGEST_FIRST {
            let pattern = format!(r"^(.+?)\s+{}$", regex::escape(roman));
            let re = Regex::new(&pattern).ok()?;
            let caps = re.captures(title_after_comiket_prefix)?;
            let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
            let vol = *roman_map.get(*roman)?;
            return Some((base, VolumeSortKey::int(vol)));
        }
        None
    }

    fn try_contiguous_roman_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let roman_map = roman_to_volume_int();
        for roman in ROMAN_SUFFIXES_CONTIGUOUS_LONGEST_FIRST {
            if !title_after_comiket_prefix.ends_with(roman) {
                continue;
            }
            let raw_base = &title_after_comiket_prefix[..title_after_comiket_prefix.len() - roman.len()];
            let base = Self::series_base_name_or_null(raw_base)?;
            let vol = *roman_map.get(*roman)?;
            return Some((base, VolumeSortKey::int(vol)));
        }
        None
    }

    fn try_contiguous_single_roman_volume(
        title_after_comiket_prefix: &str,
    ) -> Option<MappedSeriesVolume> {
        let chars: Vec<char> = title_after_comiket_prefix.chars().collect();
        if chars.len() < 2 {
            return None;
        }
        let suffix_ch = chars[chars.len() - 1];
        if suffix_ch != 'I' && suffix_ch != 'V' && suffix_ch != 'X' {
            return None;
        }
        let suffix = suffix_ch.to_string();
        let raw_base: String = chars[..chars.len() - 1].iter().collect();
        let base = Self::series_base_name_or_null(&raw_base)?;
        let prev_char = base.chars().last()?;
        let prev_code = prev_char as u32;
        if Self::is_ascii_digit(prev_code) || Self::is_ascii_letter(prev_code) {
            return None;
        }
        let vol = *roman_to_volume_int().get(suffix.as_str())?;
        Some((base, VolumeSortKey::int(vol)))
    }

    fn try_jk_kuppuku_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = JK_KUPPUKU_PATTERN.captures(title_after_comiket_prefix)?;
        const BASE: &str = "JK屈服拘束";
        let digits = caps.get(1)?.as_str();
        let vol = if digits.is_empty() {
            1
        } else {
            digits.parse().ok()?
        };
        Some((BASE.to_string(), VolumeSortKey::int(vol)))
    }

    fn try_shuryou_kouzou_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        if !title_after_comiket_prefix.starts_with(K_SHURYOU_KOUZOU_PREFIX) {
            return None;
        }
        let rest = title_after_comiket_prefix[K_SHURYOU_KOUZOU_PREFIX.len()..].trim_start();
        let vol = if rest.contains('α') {
            1
        } else if rest.contains('β') {
            2
        } else if rest.contains("NTR") {
            3
        } else if rest.contains("番外編") {
            4
        } else {
            return None;
        };
        Some((
            K_SHURYOU_KOUZOU_PREFIX.to_string(),
            VolumeSortKey::int(vol),
        ))
    }

    fn try_spaced_decimal_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = WHITESPACE_DECIMAL_SUFFIX.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let volume_sort_key: f64 = caps.get(2)?.as_str().parse().ok()?;
        Some((base, VolumeSortKey::float(volume_sort_key)))
    }

    fn try_spaced_ascii_digit_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = WHITESPACE_DIGIT_SUFFIX.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let volume_int: i32 = caps.get(2)?.as_str().parse().ok()?;
        if volume_int == 0 {
            let digit_end = caps.get(2)?.end();
            if digit_end >= title_after_comiket_prefix.len() {
                return None;
            }
        }
        Some((base, VolumeSortKey::int(volume_int)))
    }

    fn try_contiguous_decimal_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = CONTIGUOUS_DECIMAL_SUFFIX.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let last_char = base.chars().last()?;
        if Self::is_ascii_digit(last_char as u32) {
            return None;
        }
        let volume_sort_key: f64 = caps.get(2)?.as_str().parse().ok()?;
        Some((base, VolumeSortKey::float(volume_sort_key)))
    }

    fn try_dai_wa_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = WHITESPACE_DAI_WA_SUFFIX.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let numerals = caps.get(2)?.as_str();
        let volume_int = Self::parse_kanji_numerals_to_int(numerals)?;
        if volume_int < 0 {
            return None;
        }
        Some((base, VolumeSortKey::int(volume_int)))
    }

    fn try_dai_bu_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = WHITESPACE_DAI_BU_SUFFIX.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let numerals = caps.get(2)?.as_str();
        let volume_int = Self::parse_kanji_numerals_to_int(numerals)?;
        if volume_int < 0 {
            return None;
        }
        Some((base, VolumeSortKey::int(volume_int)))
    }

    fn parse_kanji_numerals_to_int(s: &str) -> Option<i32> {
        if s.is_empty() {
            return None;
        }
        let map = dai_wa_numeral_to_int();
        let chars: Vec<char> = s.chars().collect();
        if chars.len() == 1 {
            return map.get(&chars[0]).copied();
        }
        if s == "十" {
            return Some(10);
        }
        if s.starts_with('十') && chars.len() == 2 {
            let ones = map.get(&chars[1])?;
            return Some(10 + ones);
        }
        if s.ends_with('十') && chars.len() == 2 {
            let tens = map.get(&chars[0])?;
            return Some(tens * 10);
        }
        if chars.len() == 3 && chars[1] == '十' {
            let tens = map.get(&chars[0])?;
            let ones = map.get(&chars[2])?;
            return Some(tens * 10 + ones);
        }
        None
    }

    fn try_spaced_zenpen_kouhen_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = WHITESPACE_PART_SUFFIX.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let part = caps.get(2)?.as_str();
        let volume_index = if part == "前篇" || part == "前編" {
            K_VOLUME_ZENPEN
        } else {
            K_VOLUME_KOUHEN
        };
        Some((base, VolumeSortKey::int(volume_index)))
    }

    fn try_uo_shita_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = WHITESPACE_UO_SHITA_SUFFIX.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let part = caps.get(2)?.as_str();
        let volume_index = if part == "上" {
            K_VOLUME_ZENPEN
        } else {
            K_VOLUME_KOUHEN
        };
        Some((base, VolumeSortKey::int(volume_index)))
    }

    fn try_bracket_series_juan_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let caps = BRACKET_SERIES_WITH_JUAN_SUFFIX.captures(title_after_comiket_prefix)?;
        let series_name = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let volume_index: i32 = caps.get(2)?.as_str().parse().ok()?;
        if volume_index < 1 {
            return None;
        }
        Some((series_name, VolumeSortKey::int(volume_index)))
    }

    fn try_contiguous_ascii_digit_with_subtitle(
        title_after_comiket_prefix: &str,
    ) -> Option<MappedSeriesVolume> {
        let caps = CONTIGUOUS_DIGIT_WITH_SUBTITLE.captures(title_after_comiket_prefix)?;
        let base = Self::series_base_name_or_null(caps.get(1)?.as_str())?;
        let last_char = base.chars().last()?;
        if Self::is_ascii_digit(last_char as u32) {
            return None;
        }
        let volume_index: i32 = caps.get(2)?.as_str().parse().ok()?;
        if volume_index < 1 {
            return None;
        }
        Some((base, VolumeSortKey::int(volume_index)))
    }

    fn try_contiguous_ascii_digit_volume(title_after_comiket_prefix: &str) -> Option<MappedSeriesVolume> {
        let code_units: Vec<u16> = title_after_comiket_prefix.encode_utf16().collect();
        if code_units.is_empty() {
            return None;
        }
        let end = code_units.len() - 1;
        let mut index_before_digits = end as isize;
        while index_before_digits >= 0
            && Self::is_ascii_digit(code_units[index_before_digits as usize] as u32)
        {
            index_before_digits -= 1;
        }
        if index_before_digits == end as isize {
            return None;
        }
        if index_before_digits >= 0 {
            let cu = code_units[index_before_digits as usize];
            if char::from_u32(cu as u32).is_some_and(|c| c.is_whitespace()) {
                return None;
            }
        }
        let split_at = (index_before_digits + 1) as usize;
        let raw_base = utf16_substring(title_after_comiket_prefix, 0, split_at);
        let base = Self::series_base_name_or_null(raw_base)?;
        let digits = utf16_substring(title_after_comiket_prefix, split_at, code_units.len());
        let volume_index: i32 = digits.parse().ok()?;
        if volume_index < 1 {
            return None;
        }
        Some((base, VolumeSortKey::int(volume_index)))
    }

    fn series_base_name_or_null(raw_candidate: &str) -> Option<String> {
        let base = raw_candidate.trim();
        if base.is_empty() {
            return None;
        }
        if !Self::obeys_series_base_name_rule(base) {
            return None;
        }
        Some(base.to_string())
    }

    fn obeys_series_base_name_rule(base: &str) -> bool {
        let chars: Vec<char> = base.chars().collect();
        let len = chars.len();
        if len < 2 {
            return true;
        }
        !Self::is_ascii_digit(chars[len - 2] as u32) || !Self::is_ascii_digit(chars[len - 1] as u32)
    }

    fn is_ascii_digit(code_unit: u32) -> bool {
        code_unit >= K_ASCII_DIGIT_ZERO && code_unit <= K_ASCII_DIGIT_NINE
    }

    fn is_ascii_letter(code_unit: u32) -> bool {
        let is_upper = code_unit >= 0x41 && code_unit <= 0x5A;
        let is_lower = code_unit >= 0x61 && code_unit <= 0x7A;
        is_upper || is_lower
    }
}

/// 按 UTF-16 code unit 索引切分子串（与 Dart `String.substring` 语义对齐）。
fn utf16_substring(s: &str, utf16_start: usize, utf16_end: usize) -> &str {
    let mut utf16_pos = 0usize;
    let mut byte_start = s.len();
    let mut byte_end = s.len();
    for (byte_idx, ch) in s.char_indices() {
        if utf16_pos == utf16_start {
            byte_start = byte_idx;
        }
        if utf16_pos == utf16_end {
            byte_end = byte_idx;
            return &s[byte_start..byte_end];
        }
        utf16_pos += ch.len_utf16();
    }
    if utf16_pos == utf16_start {
        byte_start = s.len();
    }
    &s[byte_start..byte_end]
}
