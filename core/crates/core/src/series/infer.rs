use std::collections::HashMap;

use super::clustering::SeriesTitleClustering;
use super::title_mapping::ComicTitleToSeriesItemMapping;
use super::volume_key::VolumeSortKey;

/// 参与推断的单本漫画（comic_id + 可见标题）。
#[derive(Debug, Clone)]
pub struct ComicTitleInput {
    pub comic_id: String,
    pub title: String,
}

/// 推断组内一条漫画（已按卷序、comic_id 排序）。
#[derive(Debug, Clone)]
pub struct InferredVolumeEntry {
    pub comic_id: String,
    pub volume_sort_key: VolumeSortKey,
}

/// 同一系列基名下一组可写入系列的漫画。
#[derive(Debug, Clone)]
pub struct InferredSeriesGroup {
    pub series_name: String,
    pub entries: Vec<InferredVolumeEntry>,
}

/// 仅标题列表推断结果（用于黄金测试与 UI）。
#[derive(Debug, Clone)]
pub struct InferredSeriesFromTitlesResult {
    pub series_name: String,
    pub index_by_title: HashMap<String, i32>,
}

struct ResolvedLine {
    comic_id: String,
    original_title: String,
    cluster_key: String,
    series_display_name: String,
    volume_sort_key: VolumeSortKey,
}

struct SeriesBatchInferenceResolver<'a> {
    title_mapping: &'a ComicTitleToSeriesItemMapping,
}

impl<'a> SeriesBatchInferenceResolver<'a> {
    fn new(title_mapping: &'a ComicTitleToSeriesItemMapping) -> Self {
        Self { title_mapping }
    }

    fn resolve(&self, comics: &[ComicTitleInput]) -> Vec<ResolvedLine> {
        let mut slots: Vec<Option<ResolvedLine>> = vec![None; comics.len()];
        let mut cluster_key_to_display: HashMap<String, String> = HashMap::new();

        for (i, c) in comics.iter().enumerate() {
            let normalized = SeriesTitleClustering::normalize_title_text(&c.title);
            if let Some((series_name, volume_sort_key)) = self
                .title_mapping
                .map_comic_title_to_series_volume(&normalized)
            {
                let key = SeriesTitleClustering::cluster_key_from_series_name(&series_name);
                cluster_key_to_display
                    .entry(key.clone())
                    .or_insert_with(|| key.clone());
                slots[i] = Some(ResolvedLine {
                    comic_id: c.comic_id.clone(),
                    original_title: c.title.clone(),
                    cluster_key: key.clone(),
                    series_display_name: key,
                    volume_sort_key,
                });
            }
        }

        for (i, c) in comics.iter().enumerate() {
            if slots[i].is_some() {
                continue;
            }
            let stripped =
                ComicTitleToSeriesItemMapping::strip_comiket_prefixes(c.title.trim());
            if SeriesTitleClustering::ends_with_soushuuhen(&stripped) {
                let key = SeriesTitleClustering::cluster_key_from_full_title(&c.title);
                if let Some(display) = cluster_key_to_display.get(&key).cloned() {
                    slots[i] = Some(ResolvedLine {
                        comic_id: c.comic_id.clone(),
                        original_title: c.title.clone(),
                        cluster_key: key,
                        series_display_name: display,
                        volume_sort_key: VolumeSortKey::int(-1),
                    });
                }
            }
        }

        for (i, c) in comics.iter().enumerate() {
            if slots[i].is_some() {
                continue;
            }
            let key = SeriesTitleClustering::cluster_key_from_full_title(&c.title);
            let Some(display) = cluster_key_to_display.get(&key).cloned() else {
                continue;
            };
            slots[i] = Some(ResolvedLine {
                comic_id: c.comic_id.clone(),
                original_title: c.title.clone(),
                cluster_key: key,
                series_display_name: display,
                volume_sort_key: VolumeSortKey::int(1),
            });
        }

        let partial: Vec<ResolvedLine> = slots.iter().filter_map(|s| s.clone()).collect();
        let mut by_key: HashMap<String, Vec<ResolvedLine>> = HashMap::new();
        for line in &partial {
            if line.volume_sort_key == VolumeSortKey::int(-1) {
                continue;
            }
            by_key
                .entry(line.cluster_key.clone())
                .or_default()
                .push(line.clone());
        }

        for i in 0..comics.len() {
            let Some(ref s) = slots[i] else {
                continue;
            };
            if s.volume_sort_key != VolumeSortKey::int(-1) {
                continue;
            }
            let Some(bucket) = by_key.get(&s.cluster_key) else {
                continue;
            };
            if bucket.is_empty() {
                continue;
            }
            let max_vol = bucket
                .iter()
                .map(|e| e.volume_sort_key)
                .max_by(|a, b| VolumeSortKey::compare(*a, *b))
                .unwrap_or(VolumeSortKey::int(0));
            let next_vol = match max_vol {
                VolumeSortKey::Int(v) => VolumeSortKey::Int(v + 1),
                VolumeSortKey::Float(v) => VolumeSortKey::Float(v + 1.0),
            };
            slots[i] = Some(ResolvedLine {
                comic_id: s.comic_id.clone(),
                original_title: s.original_title.clone(),
                cluster_key: s.cluster_key.clone(),
                series_display_name: s.series_display_name.clone(),
                volume_sort_key: next_vol,
            });
        }

        slots.into_iter().flatten().collect()
    }
}

/// 将已映射的标题按系列基名分桶，过滤小组并排序（无 I/O）。
#[derive(Debug, Clone, Copy, Default)]
pub struct InferredSeriesGrouper;

impl InferredSeriesGrouper {
    pub fn build(
        &self,
        comics: &[ComicTitleInput],
        title_mapping: &ComicTitleToSeriesItemMapping,
        min_comics_per_group: usize,
    ) -> Vec<InferredSeriesGroup> {
        let resolver = SeriesBatchInferenceResolver::new(title_mapping);
        let resolved = resolver.resolve(comics);
        let mut by_base: HashMap<String, Vec<InferredVolumeEntry>> = HashMap::new();
        let mut base_to_display: HashMap<String, String> = HashMap::new();

        for line in resolved {
            by_base
                .entry(line.cluster_key.clone())
                .or_default()
                .push(InferredVolumeEntry {
                    comic_id: line.comic_id,
                    volume_sort_key: line.volume_sort_key,
                });
            base_to_display.insert(line.cluster_key, line.series_display_name);
        }

        let mut out = Vec::new();
        for (key, mut entries) in by_base {
            if entries.len() < min_comics_per_group {
                continue;
            }
            entries.sort_by(|a, b| {
                let by_vol = VolumeSortKey::compare(a.volume_sort_key, b.volume_sort_key);
                if by_vol != std::cmp::Ordering::Equal {
                    return by_vol;
                }
                a.comic_id.cmp(&b.comic_id)
            });
            let display_name = base_to_display.get(&key).cloned().unwrap_or(key);
            out.push(InferredSeriesGroup {
                series_name: display_name,
                entries,
            });
        }
        out.sort_by(|a, b| a.series_name.cmp(&b.series_name));
        out
    }
}

/// 自动从漫画标题推断系列：编排「单标题解析」与「按基名分组」两步（无 I/O）。
#[derive(Debug, Clone)]
pub struct AutoSeriesInferService {
    title_mapping: ComicTitleToSeriesItemMapping,
    grouper: InferredSeriesGrouper,
}

impl Default for AutoSeriesInferService {
    fn default() -> Self {
        Self::new()
    }
}

impl AutoSeriesInferService {
    pub fn new() -> Self {
        Self {
            title_mapping: ComicTitleToSeriesItemMapping,
            grouper: InferredSeriesGrouper,
        }
    }

    pub fn with_mapping(title_mapping: ComicTitleToSeriesItemMapping) -> Self {
        Self {
            title_mapping,
            grouper: InferredSeriesGrouper,
        }
    }

    pub fn infer_groups(
        &self,
        comics: &[ComicTitleInput],
        min_comics_per_group: usize,
    ) -> Vec<InferredSeriesGroup> {
        self.grouper
            .build(comics, &self.title_mapping, min_comics_per_group)
    }

    /// 对一批标题（无 comic_id）推断单一系列；若无法形成一组则返回 None。
    ///
    /// `index_by_title` 的键为去掉 Comic Market 前缀后的可见标题（与黄金用例一致）。
    pub fn infer_series_from_titles(
        &self,
        titles: &[String],
        min_titles_per_series: usize,
    ) -> Option<InferredSeriesFromTitlesResult> {
        let comics: Vec<ComicTitleInput> = titles
            .iter()
            .enumerate()
            .map(|(i, title)| ComicTitleInput {
                comic_id: i.to_string(),
                title: title.clone(),
            })
            .collect();

        let groups = self.infer_groups(&comics, min_titles_per_series);
        if groups.len() != 1 {
            return None;
        }
        let g = &groups[0];

        let use_dense_rank = g.entries.iter().any(|e| e.volume_sort_key.is_non_integer());

        let mut sorted = g.entries.clone();
        sorted.sort_by(|a, b| {
            let by_vol = VolumeSortKey::compare(a.volume_sort_key, b.volume_sort_key);
            if by_vol != std::cmp::Ordering::Equal {
                return by_vol;
            }
            a.comic_id.cmp(&b.comic_id)
        });

        let mut index_by_title = HashMap::new();
        if use_dense_rank {
            let mut rank = 1i32;
            for e in &sorted {
                let idx: usize = e.comic_id.parse().ok()?;
                let key = Self::index_key_for_title(&titles[idx]);
                index_by_title.insert(key, rank);
                rank += 1;
            }
        } else {
            for e in &sorted {
                let idx: usize = e.comic_id.parse().ok()?;
                let key = Self::index_key_for_title(&titles[idx]);
                index_by_title.insert(key, e.volume_sort_key.floor_i32());
            }
        }

        Some(InferredSeriesFromTitlesResult {
            series_name: g.series_name.clone(),
            index_by_title,
        })
    }

    fn index_key_for_title(title: &str) -> String {
        ComicTitleToSeriesItemMapping::strip_comiket_prefixes(title.trim())
    }
}

// Clone for ResolvedLine used in batch resolver
impl Clone for ResolvedLine {
    fn clone(&self) -> Self {
        Self {
            comic_id: self.comic_id.clone(),
            original_title: self.original_title.clone(),
            cluster_key: self.cluster_key.clone(),
            series_display_name: self.series_display_name.clone(),
            volume_sort_key: self.volume_sort_key,
        }
    }
}
