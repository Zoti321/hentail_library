use std::collections::{BTreeMap, HashSet};
use std::ops::Range;

use quick_xml::{events::Event, name::ResolveResult, NsReader};

use crate::{error::HentaiError, metadata_lock::ComicMetaField};

use super::{MetadataSnapshot, MetadataWriteIntent, EXTENSION_NAMESPACE};

struct Child {
    key: String,
    range: Range<usize>,
    text: String,
}

struct Document {
    children: Vec<Child>,
    close: usize,
    empty_root: bool,
}

fn invalid(message: impl Into<String>) -> HentaiError {
    HentaiError::validation(format!("ComicInfo: {}", message.into()))
}

fn parse(xml: &str) -> Result<Document, HentaiError> {
    let mut reader = NsReader::from_str(xml);
    let mut depth = 0;
    let mut root_seen = false;
    let mut close = 0;
    let mut empty_root = false;
    let mut children = Vec::new();
    let mut current: Option<Child> = None;
    let mut seen = HashSet::new();
    loop {
        let before = reader.buffer_position() as usize;
        let (namespace, event) = reader
            .read_resolved_event()
            .map_err(|err| invalid(err.to_string()))?;
        let application_ns = matches!(&namespace, ResolveResult::Bound(ns) if ns.as_ref() == EXTENSION_NAMESPACE.as_bytes());
        let standard_ns = matches!(namespace, ResolveResult::Unbound);
        if matches!(namespace, ResolveResult::Unknown(_)) {
            return Err(invalid("Unbound namespace prefix"));
        }
        match event {
            Event::Start(ref start) | Event::Empty(ref start) => {
                let empty = matches!(event, Event::Empty(_));
                for attribute in start.attributes() {
                    attribute
                        .map_err(|err| invalid(err.to_string()))?
                        .decode_and_unescape_value(reader.decoder())
                        .map_err(|err| invalid(err.to_string()))?;
                }
                let name = String::from_utf8_lossy(start.local_name().as_ref()).into_owned();
                if depth == 0 {
                    if root_seen || name != "ComicInfo" || !standard_ns {
                        return Err(invalid("Expected one unnamespaced ComicInfo root"));
                    }
                    root_seen = true;
                    empty_root = empty;
                    if empty {
                        close = before;
                    }
                } else if depth == 1 {
                    let key = if application_ns && name == "Metadata" {
                        "@extension".to_owned()
                    } else if standard_ns {
                        name
                    } else {
                        String::new()
                    };
                    if owned_key(&key) && !seen.insert(key.clone()) {
                        return Err(invalid(format!("Conflicting duplicate {key}")));
                    }
                    let child = Child {
                        key,
                        range: before..reader.buffer_position() as usize,
                        text: String::new(),
                    };
                    if empty {
                        children.push(child);
                    } else {
                        current = Some(child);
                    }
                } else if current.as_ref().is_some_and(|child| owned_key(&child.key)) {
                    return Err(invalid("Metadata scalar contains nested elements"));
                }
                if !empty {
                    depth += 1;
                }
            }
            Event::End(_) => {
                if depth == 0 {
                    return Err(invalid("Unexpected closing element"));
                }
                depth -= 1;
                if depth == 1 {
                    if let Some(mut child) = current.take() {
                        child.range.end = reader.buffer_position() as usize;
                        children.push(child);
                    }
                } else if depth == 0 {
                    close = before;
                }
            }
            Event::Text(text) => {
                let text = text.unescape().map_err(|err| invalid(err.to_string()))?;
                if !valid_xml_text(&text) {
                    return Err(invalid("Forbidden XML character"));
                }
                if depth == 0 && !text.trim().is_empty() {
                    return Err(invalid("Text outside document root"));
                }
                if depth == 2 {
                    if let Some(child) = &mut current {
                        child.text.push_str(&text);
                    }
                }
            }
            Event::CData(text) => {
                if depth == 0 {
                    return Err(invalid("CDATA outside document root"));
                }
                if depth == 2 {
                    if let Some(child) = &mut current {
                        child
                            .text
                            .push_str(&text.decode().map_err(|err| invalid(err.to_string()))?);
                    }
                }
            }
            Event::DocType(_) => return Err(invalid("DTD is unsupported")),
            Event::Eof => break,
            _ => {}
        }
    }
    if !root_seen || depth != 0 {
        return Err(invalid("Incomplete document"));
    }
    Ok(Document {
        children,
        close,
        empty_root,
    })
}

fn owned_key(key: &str) -> bool {
    matches!(
        key,
        "Title"
            | "Summary"
            | "Year"
            | "Month"
            | "Day"
            | "Writer"
            | "Tags"
            | "Characters"
            | "LanguageISO"
            | "AgeRating"
            | "@extension"
    )
}

fn names(raw: &str) -> Vec<String> {
    crate::metadata_lock::normalize_names(
        &raw.split([',', ';']).map(str::to_owned).collect::<Vec<_>>(),
    )
}

pub fn read_comic_info(xml: &str) -> Result<MetadataSnapshot, HentaiError> {
    let document = parse(xml)?;
    let values: BTreeMap<_, _> = document
        .children
        .iter()
        .map(|child| (child.key.as_str(), child.text.as_str()))
        .collect();
    let value = |key: &str| values.get(key).copied().unwrap_or_default();
    let mut authors = Vec::new();
    for role in [
        "Writer",
        "Penciller",
        "Inker",
        "Colorist",
        "Letterer",
        "CoverArtist",
    ] {
        for author in names(value(role)) {
            if !authors.contains(&author) {
                authors.push(author);
            }
        }
    }
    let language = match value("LanguageISO")
        .trim()
        .split('-')
        .next()
        .unwrap_or_default()
        .to_ascii_lowercase()
        .as_str()
    {
        "zh" => Some("Chinese".to_owned()),
        "ja" => Some("Japanese".to_owned()),
        "en" => Some("English".to_owned()),
        "ko" => Some("Korean".to_owned()),
        "es" => Some("Spanish".to_owned()),
        "" => None,
        _ => Some(value("LanguageISO").trim().to_owned()),
    };
    let date = (
        value("Year").parse(),
        value("Month").parse(),
        value("Day").parse(),
    );
    let snapshot = MetadataSnapshot {
        title: value("Title").to_owned(),
        description: (!value("Summary").is_empty()).then(|| value("Summary").to_owned()),
        published_at: match date {
            (Ok(year), Ok(month), Ok(day)) => date_ms(year, month, day),
            _ => None,
        },
        content_rating: match value("AgeRating").trim() {
            "Adults Only 18+" | "R18+" | "X18+" => "r18",
            "Everyone" | "G" | "Early Childhood" | "Everyone 10+" | "Kids to Adults" | "PG"
            | "Teen" | "M" | "MA15+" | "Mature 17+" => "safe",
            _ => "unknown",
        }
        .to_owned(),
        authors,
        tags: names(value("Tags")),
        language,
        parodies: Vec::new(),
        characters: names(value("Characters")),
    };
    Ok(match values.get("@extension") {
        Some(raw) => snapshot.with_extension(raw),
        None => snapshot,
    })
}

pub fn update_comic_info(
    existing: Option<&str>,
    intent: &MetadataWriteIntent,
) -> Result<String, HentaiError> {
    let source =
        existing.unwrap_or("<?xml version=\"1.0\" encoding=\"utf-8\"?><ComicInfo></ComicInfo>");
    let document = parse(source)?;
    let snapshot = &intent.snapshot;
    if std::iter::once(snapshot.title.as_str())
        .chain(snapshot.description.as_deref())
        .chain(snapshot.authors.iter().map(String::as_str))
        .chain(snapshot.tags.iter().map(String::as_str))
        .chain(snapshot.characters.iter().map(String::as_str))
        .any(|text| !valid_xml_text(text))
    {
        return Err(invalid("Metadata contains a forbidden XML character"));
    }
    let mut replacements = BTreeMap::new();
    let mut put = |key: &str, value: String| {
        replacements.insert(key.to_owned(), value);
    };
    for field in &intent.fields {
        match field {
            ComicMetaField::Title => put("Title", snapshot.title.clone()),
            ComicMetaField::Description => {
                put("Summary", snapshot.description.clone().unwrap_or_default())
            }
            ComicMetaField::PublishedAt => {
                let date = snapshot
                    .published_at
                    .map(|ms| civil_date(ms.div_euclid(86_400_000)));
                put(
                    "Year",
                    date.map(|(y, _, _)| y.to_string())
                        .unwrap_or_else(|| "-1".to_owned()),
                );
                put(
                    "Month",
                    date.map(|(_, m, _)| m.to_string())
                        .unwrap_or_else(|| "-1".to_owned()),
                );
                put(
                    "Day",
                    date.map(|(_, _, d)| d.to_string())
                        .unwrap_or_else(|| "-1".to_owned()),
                );
            }
            ComicMetaField::Authors => put("Writer", snapshot.authors.join(", ")),
            ComicMetaField::Tags => put("Tags", snapshot.tags.join(", ")),
            ComicMetaField::Characters => put("Characters", snapshot.characters.join(", ")),
            ComicMetaField::Languages => put(
                "LanguageISO",
                match snapshot.language.as_deref() {
                    Some("Chinese") => "zh",
                    Some("Japanese") => "ja",
                    Some("English") => "en",
                    Some("Korean") => "ko",
                    Some("Spanish") => "es",
                    _ => "",
                }
                .to_owned(),
            ),
            ComicMetaField::ContentRating => put(
                "AgeRating",
                if snapshot.content_rating == "r18" {
                    "Adults Only 18+"
                } else {
                    "Unknown"
                }
                .to_owned(),
            ),
            ComicMetaField::Parodies => {}
        }
    }
    let extension = document
        .children
        .iter()
        .find(|child| child.key == "@extension")
        .map(|child| child.text.as_str());
    let extension = intent.extension_json(extension)?;
    let extension_xml = format!(
        "<hl:Metadata xmlns:hl=\"{EXTENSION_NAMESPACE}\">{}</hl:Metadata>",
        quick_xml::escape::escape(&extension)
    );
    let mut output = String::new();
    let mut cursor = 0;
    let existing_keys: HashSet<_> = document
        .children
        .iter()
        .map(|child| child.key.as_str())
        .collect();
    let mut additions: Vec<_> = replacements
        .iter()
        .filter(|(key, _)| !existing_keys.contains(key.as_str()))
        .map(|(key, value)| (key.clone(), value.clone()))
        .collect();
    additions.sort_by_key(|(key, _)| schema_rank(key));
    let mut additions = additions.into_iter().peekable();
    for child in &document.children {
        output.push_str(&source[cursor..child.range.start]);
        if schema_rank(&child.key) < usize::MAX {
            while additions
                .peek()
                .is_some_and(|(key, _)| schema_rank(key) < schema_rank(&child.key))
            {
                let (key, value) = additions.next().expect("peeked addition");
                output.push_str(&element(&key, &value));
            }
        }
        let replacement = if child.key == "@extension" {
            Some(extension_xml.clone())
        } else {
            replacements
                .remove(&child.key)
                .map(|value| element(&child.key, &value))
        };
        if let Some(replacement) = replacement {
            output.push_str(&replacement);
        } else {
            output.push_str(&source[child.range.clone()]);
        }
        cursor = child.range.end;
    }
    if document.empty_root {
        output.push_str(&source[..document.close]);
        // Keep root attributes/namespaces when expanding a self-closing root.
        let root_end = source[document.close..]
            .find("/>")
            .ok_or_else(|| invalid("Invalid empty root"))?
            + document.close;
        output.push_str(&source[document.close..root_end]);
        output.push('>');
        cursor = root_end + 2;
    } else {
        output.push_str(&source[cursor..document.close]);
        cursor = document.close;
    }
    for (key, value) in additions {
        output.push_str(&element(&key, &value));
    }
    if !document
        .children
        .iter()
        .any(|child| child.key == "@extension")
    {
        output.push_str(&extension_xml);
    }
    if document.empty_root {
        output.push_str("</ComicInfo>");
    }
    output.push_str(&source[cursor..]);
    parse(&output)?;
    Ok(output)
}

fn schema_rank(name: &str) -> usize {
    [
        "Title",
        "Series",
        "Number",
        "Count",
        "Volume",
        "AlternateSeries",
        "AlternateNumber",
        "AlternateCount",
        "Summary",
        "Notes",
        "Year",
        "Month",
        "Day",
        "Writer",
        "Penciller",
        "Inker",
        "Colorist",
        "Letterer",
        "CoverArtist",
        "Editor",
        "Translator",
        "Publisher",
        "Imprint",
        "Genre",
        "Tags",
        "Web",
        "PageCount",
        "LanguageISO",
        "Format",
        "BlackAndWhite",
        "Manga",
        "Characters",
        "Teams",
        "Locations",
        "ScanInformation",
        "StoryArc",
        "StoryArcNumber",
        "SeriesGroup",
        "AgeRating",
        "Pages",
        "CommunityRating",
        "MainCharacterOrTeam",
        "Review",
        "GTIN",
    ]
    .iter()
    .position(|candidate| *candidate == name)
    .unwrap_or(usize::MAX)
}

fn element(name: &str, text: &str) -> String {
    format!("<{name}>{}</{name}>", quick_xml::escape::escape(text))
}

fn valid_xml_text(text: &str) -> bool {
    text.chars().all(|ch| matches!(ch, '\u{9}' | '\u{a}' | '\u{d}' | '\u{20}'..='\u{d7ff}' | '\u{e000}'..='\u{fffd}' | '\u{10000}'..='\u{10ffff}'))
}

pub(super) fn civil_date(days: i64) -> (i64, i64, i64) {
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let mut year = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = mp + if mp < 10 { 3 } else { -9 };
    year += i64::from(month <= 2);
    (year, month, day)
}

fn date_ms(year: i64, month: i64, day: i64) -> Option<i64> {
    if !(1..=9999).contains(&year) || !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }
    let y = year - i64::from(month <= 2);
    let era = y.div_euclid(400);
    let yoe = y - era * 400;
    let mp = month + if month > 2 { -3 } else { 9 };
    let days =
        era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + (153 * mp + 2) / 5 + day - 1 - 719468;
    (civil_date(days) == (year, month, day)).then_some(days * 86_400_000)
}

pub(super) fn parse_date(raw: &str) -> Option<i64> {
    let date = raw.get(..10)?;
    let mut parts = date.split('-');
    date_ms(
        parts.next()?.parse().ok()?,
        parts.next()?.parse().ok()?,
        parts.next()?.parse().ok()?,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_write_roundtrips_exact_values_and_can_be_repeated() {
        let snapshot = MetadataSnapshot {
            title: "你好 <&>".into(),
            authors: vec!["A,B".into(), "D;E".into()],
            description: Some("line\nline".into()),
            published_at: Some(-1),
            content_rating: "safe".into(),
            language: Some("Esperanto".into()),
            parodies: vec!["IP".into()],
            tags: vec!["a,b".into()],
            characters: vec!["Character".into()],
        };
        let intent = MetadataWriteIntent::full(snapshot.clone());
        let xml = update_comic_info(None, &intent).unwrap();
        assert_eq!(read_comic_info(&xml).unwrap(), snapshot);
        assert_eq!(update_comic_info(Some(&xml), &intent).unwrap(), xml);
    }

    #[test]
    fn sparse_updates_keep_unknown_nodes_roles_comments_and_cdata_untouched() {
        let source = "<ComicInfo custom='yes'><!--keep--><Title><![CDATA[old]]></Title><Penciller>A</Penciller><Summary>keep</Summary><x:Future xmlns:x='other'><x:Nested/></x:Future></ComicInfo>";
        let intent = MetadataWriteIntent {
            snapshot: MetadataSnapshot::default(),
            fields: [ComicMetaField::Description].into(),
        };
        let xml = update_comic_info(Some(source), &intent).unwrap();
        assert!(xml.contains(
            "<!--keep--><Title><![CDATA[old]]></Title><Penciller>A</Penciller><Summary></Summary>"
        ));
        assert!(xml.contains("<x:Future xmlns:x='other'><x:Nested/></x:Future>"));
        let imported = read_comic_info(&xml).unwrap();
        assert_eq!(imported.title, "old");
        assert_eq!(imported.authors, ["A"]);
        assert_eq!(imported.description, None);
    }

    #[test]
    fn malformed_duplicate_or_unsafe_documents_are_never_overwritten() {
        let intent = MetadataWriteIntent::full(MetadataSnapshot::default());
        for xml in [
            "<ComicInfo>",
            "<ComicInfo><Title>A</Title><Title>B</Title></ComicInfo>",
            "<Other/>",
            "<!DOCTYPE ComicInfo><ComicInfo/>",
            "<ComicInfo/><ComicInfo/>",
            "<ComicInfo><Title>&unknown;</Title></ComicInfo>",
        ] {
            assert!(update_comic_info(Some(xml), &intent).is_err(), "{xml}");
        }
    }

    #[test]
    fn empty_root_retains_attributes_and_standard_date_is_validated() {
        let xml = update_comic_info(
            Some("<?xml version='1.0'?><ComicInfo marker='keep'/>"),
            &MetadataWriteIntent::full(MetadataSnapshot::default()),
        )
        .unwrap();
        assert!(xml.contains("<ComicInfo marker='keep'>"));
        assert!(read_comic_info(&xml).is_ok());
        let valid = "<ComicInfo><Year>2024</Year><Month>2</Month><Day>29</Day><LanguageISO>zh-Hant</LanguageISO><AgeRating>R18+</AgeRating></ComicInfo>";
        let snapshot = read_comic_info(valid).unwrap();
        assert!(snapshot.published_at.is_some());
        assert_eq!(snapshot.language.as_deref(), Some("Chinese"));
        assert_eq!(snapshot.content_rating, "r18");
        assert!(read_comic_info(&valid.replace("2024", "2023"))
            .unwrap()
            .published_at
            .is_none());
    }
}
