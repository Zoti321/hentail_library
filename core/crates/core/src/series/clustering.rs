use super::title_mapping::ComicTitleToSeriesItemMapping;

/// 供批量推断使用的标题预处理与系列聚类键（无 I/O）。
pub struct SeriesTitleClustering;

impl SeriesTitleClustering {
    /// 将 ASCII `...` 规范为 Unicode 省略号 `…`（与常见标题写法对齐）。
    pub fn normalize_title_text(title: &str) -> String {
        title.trim().replace("...", "…")
    }

    /// 去掉装饰用心形符号，便于「おほっ♥…」与「おほっ…」合并。
    pub fn strip_heart_symbols(title: &str) -> String {
        title
            .replace('\u{2665}', "")
            .replace('\u{2661}', "")
            .trim()
            .to_string()
    }

    /// 解析得到的基名：去掉末尾全角句号，便于与无句号标题合并。
    pub fn canonicalize_parsed_series_name(series_name: &str) -> String {
        let mut s = series_name.trim().to_string();
        while s.ends_with('。') {
            s = s[..s.len() - '。'.len_utf8()].trim_end().to_string();
        }
        s
    }

    /// 与 [canonicalize_parsed_series_name] 一致后再 [strip_heart_symbols]，作聚类桶键。
    pub fn cluster_key_from_series_name(raw_series_name: &str) -> String {
        Self::strip_heart_symbols(&Self::canonicalize_parsed_series_name(raw_series_name))
    }

    /// 未解析标题的聚类键：取第一个 `。` 之前的部分（与 [canonicalize_parsed_series_name] 对齐）。
    pub fn cluster_key_from_unparsed_title(stripped_after_comiket: &str) -> String {
        let n = Self::normalize_title_text(stripped_after_comiket);
        let heart = Self::strip_heart_symbols(&n);
        if let Some(idx) = heart.find('。') {
            return heart[..idx].trim().to_string();
        }
        heart.trim().to_string()
    }

    /// 与 [cluster_key_from_unparsed_title] 相同，但接受完整标题（会先 strip Comiket）。
    pub fn cluster_key_from_full_title(title: &str) -> String {
        Self::cluster_key_from_unparsed_title(&ComicTitleToSeriesItemMapping::strip_comiket_prefixes(
            title,
        ))
    }

    pub fn ends_with_soushuuhen(stripped_after_comiket: &str) -> bool {
        Self::normalize_title_text(stripped_after_comiket).ends_with("総集編")
    }
}
