use super::{
    local::{file_digest, io_error, PreparedLocalWrite},
    xml, MetadataSnapshot, MetadataWriteIntent, EXTENSION_NAMESPACE,
};
use crate::{error::HentaiError, metadata_lock::ComicMetaField};
use std::{
    collections::BTreeMap,
    fmt::Write as _,
    fs::File,
    io::{Read, Write},
    path::Path,
};
use zip::{write::SimpleFileOptions, ZipArchive, ZipWriter};
const DC: &str = "http://purl.org/dc/elements/1.1/";

fn opf_path<R: Read + std::io::Seek>(archive: &mut ZipArchive<R>) -> Result<String, HentaiError> {
    let mut container = String::new();
    archive
        .by_name("META-INF/container.xml")
        .map_err(io_error)?
        .read_to_string(&mut container)
        .map_err(io_error)?;
    let paths = xml::nodes(&container)?
        .into_iter()
        .filter(|node| node.name == "rootfile")
        .filter_map(|node| node.attr("full-path").map(str::to_owned))
        .collect::<Vec<_>>();
    if paths.len() != 1
        || Path::new(&paths[0]).is_absolute()
        || paths[0].split('/').any(|part| part == "..")
    {
        return Err(io_error("Ambiguous or unsafe EPUB package"));
    }
    Ok(paths[0].clone())
}

#[must_use]
pub fn container_package_path(container: &str) -> Option<String> {
    let paths = xml::nodes(container)
        .ok()?
        .into_iter()
        .filter(|node| node.name == "rootfile")
        .filter_map(|node| node.attr("full-path").map(str::to_owned))
        .collect::<Vec<_>>();
    (paths.len() == 1).then(|| paths[0].clone())
}

pub fn read_opf(opf: &str) -> Result<MetadataSnapshot, HentaiError> {
    let nodes = xml::nodes(opf)?;
    let mut snapshot = MetadataSnapshot {
        content_rating: "unknown".into(),
        ..Default::default()
    };
    for node in &nodes {
        if node.namespace == DC {
            match node.name.as_str() {
                "title" if snapshot.title.is_empty() => {
                    snapshot.title.clear();
                    snapshot.title.push_str(node.text.trim());
                }
                "creator" => {
                    for author in node
                        .text
                        .split([',', ';'])
                        .map(str::trim)
                        .filter(|value| !value.is_empty())
                    {
                        if !snapshot.authors.iter().any(|name| name == author) {
                            snapshot.authors.push(author.to_owned());
                        }
                    }
                }
                "description" => snapshot.description = Some(node.text.clone()),
                "subject" => snapshot.tags.push(node.text.clone()),
                "date" => snapshot.published_at = super::comic_info::parse_date(&node.text),
                "language" if snapshot.language.is_none() => {
                    snapshot.language = Some(language_name(&node.text));
                }
                _ => {}
            }
        }
    }
    if let Some(node) = nodes.iter().find(|node| is_extension(node)) {
        snapshot = snapshot.with_extension(node.attr("content").unwrap_or(&node.text));
    }
    Ok(snapshot)
}

fn is_extension(node: &xml::Node) -> bool {
    node.name == "meta"
        && (node.attr("property") == Some("hl:metadata")
            || node.attr("name") == Some(EXTENSION_NAMESPACE))
}
fn language_name(code: &str) -> String {
    match code
        .trim()
        .split('-')
        .next()
        .unwrap_or_default()
        .to_lowercase()
        .as_str()
    {
        "zh" => "Chinese",
        "ja" => "Japanese",
        "en" => "English",
        "ko" => "Korean",
        "es" => "Spanish",
        _ => code.trim(),
    }
    .to_owned()
}

fn update_opf(opf: &str, intent: &MetadataWriteIntent) -> Result<String, HentaiError> {
    let nodes = xml::nodes(opf)?;
    let package = nodes
        .iter()
        .find(|node| node.name == "package")
        .ok_or_else(|| io_error("Missing EPUB package"))?;
    let version = package.attr("version").unwrap_or_default();
    if !version.starts_with("2.") && !version.starts_with("3.") {
        return Err(io_error("Unsupported EPUB package version"));
    }
    let metadata = nodes
        .iter()
        .find(|node| node.name == "metadata" && node.depth == package.depth + 1)
        .ok_or_else(|| io_error("Missing EPUB metadata"))?;
    if metadata.empty {
        return Err(io_error("Invalid empty EPUB metadata"));
    }
    let fields = opf_intent_fields(intent);
    let mut edits = Vec::new();
    let mut additions = String::new();
    push_epub3_hl_prefix_edits(opf, package, &mut edits)?;
    apply_opf_dc_edits(&nodes, metadata, &fields, &mut edits, &mut additions)?;
    apply_opf_extension_and_modified(intent, &nodes, version, &mut edits, &mut additions)?;
    edits.push((metadata.content.end..metadata.content.end, additions));
    xml::replace(opf, edits)
}

fn opf_intent_fields(intent: &MetadataWriteIntent) -> BTreeMap<&'static str, Vec<String>> {
    let mut fields: BTreeMap<&str, Vec<String>> = BTreeMap::new();
    for field in &intent.fields {
        match field {
            ComicMetaField::Title => {
                fields.insert("title", vec![intent.snapshot.title.clone()]);
            }
            ComicMetaField::Authors => {
                fields.insert("creator", intent.snapshot.authors.clone());
            }
            ComicMetaField::Description => {
                fields.insert(
                    "description",
                    intent.snapshot.description.clone().into_iter().collect(),
                );
            }
            ComicMetaField::Tags => {
                fields.insert("subject", intent.snapshot.tags.clone());
            }
            ComicMetaField::Languages => {
                fields.insert(
                    "language",
                    intent
                        .snapshot
                        .language
                        .as_deref()
                        .map(|name| {
                            match name {
                                "Chinese" => "zh",
                                "Japanese" => "ja",
                                "English" => "en",
                                "Korean" => "ko",
                                "Spanish" => "es",
                                _ => "und",
                            }
                            .to_owned()
                        })
                        .into_iter()
                        .collect(),
                );
            }
            ComicMetaField::PublishedAt => {
                fields.insert(
                    "date",
                    intent
                        .snapshot
                        .published_at
                        .map(|ms| {
                            let (year, month, day) =
                                super::comic_info::civil_date(ms.div_euclid(86_400_000));
                            format!("{year:04}-{month:02}-{day:02}")
                        })
                        .into_iter()
                        .collect(),
                );
            }
            _ => {}
        }
    }
    fields
}

fn push_epub3_hl_prefix_edits(
    opf: &str,
    package: &xml::Node,
    edits: &mut Vec<(std::ops::Range<usize>, String)>,
) -> Result<(), HentaiError> {
    let version = package.attr("version").unwrap_or_default();
    if !version.starts_with("3.") {
        return Ok(());
    }
    let prefix = package.attr("prefix").unwrap_or_default();
    if prefix.split_whitespace().any(|part| part == "hl:")
        && !prefix.contains(&format!("hl: {EXTENSION_NAMESPACE}"))
    {
        return Err(io_error(
            "EPUB hl metadata prefix is already bound differently",
        ));
    }
    if prefix.contains(&format!("hl: {EXTENSION_NAMESPACE}")) {
        return Ok(());
    }
    let opening = &opf[package.range.start..package.content.start];
    let opening = if prefix.is_empty() {
        format!(
            "{} prefix=\"hl: {EXTENSION_NAMESPACE}\">",
            &opening[..opening.len() - 1]
        )
    } else {
        let quote_double = format!("prefix=\"{}\"", xml::escaped(prefix));
        let quote_single = format!("prefix='{prefix}'");
        let replacement = format!(
            "prefix=\"{} hl: {EXTENSION_NAMESPACE}\"",
            xml::escaped(prefix)
        );
        if opening.contains(&quote_double) {
            opening.replace(&quote_double, &replacement)
        } else if opening.contains(&quote_single) {
            opening.replace(&quote_single, &replacement)
        } else {
            return Err(io_error("Unsupported EPUB prefix attribute spelling"));
        }
    };
    edits.push((package.range.start..package.content.start, opening));
    Ok(())
}

fn apply_opf_dc_edits(
    nodes: &[xml::Node],
    metadata: &xml::Node,
    fields: &BTreeMap<&str, Vec<String>>,
    edits: &mut Vec<(std::ops::Range<usize>, String)>,
    additions: &mut String,
) -> Result<(), HentaiError> {
    for (name, values) in fields {
        let existing = nodes
            .iter()
            .filter(|node| {
                node.depth == metadata.depth + 1 && node.namespace == DC && node.name == *name
            })
            .collect::<Vec<_>>();
        for node in existing.iter().skip(values.len()) {
            if node.attr("id").is_some_and(|id| {
                nodes
                    .iter()
                    .any(|other| other.attr("refines") == Some(&format!("#{id}")))
            }) {
                return Err(io_error("Cannot safely remove referenced EPUB metadata"));
            }
        }
        for (index, node) in existing.iter().enumerate() {
            if let Some(value) = values.get(index) {
                if node.empty {
                    edits.push((
                        node.range.clone(),
                        format!(
                            "<dc:{name} xmlns:dc=\"{DC}\">{}</dc:{name}>",
                            xml::escaped(value)
                        ),
                    ));
                } else {
                    edits.push((node.content.clone(), xml::escaped(value)));
                }
            } else {
                edits.push((node.range.clone(), String::new()));
            }
        }
        for value in values.iter().skip(existing.len()) {
            let _ = write!(
                additions,
                "<dc:{name} xmlns:dc=\"{DC}\">{}</dc:{name}>",
                xml::escaped(value)
            );
        }
    }
    Ok(())
}

fn apply_opf_extension_and_modified(
    intent: &MetadataWriteIntent,
    nodes: &[xml::Node],
    version: &str,
    edits: &mut Vec<(std::ops::Range<usize>, String)>,
    additions: &mut String,
) -> Result<(), HentaiError> {
    let extension_nodes = nodes
        .iter()
        .filter(|node| is_extension(node))
        .collect::<Vec<_>>();
    if extension_nodes.len() > 1 {
        return Err(io_error("Conflicting EPUB metadata extensions"));
    }
    let extension = intent.extension_json(
        extension_nodes
            .first()
            .map(|node| node.attr("content").unwrap_or(&node.text)),
    )?;
    let extension = if version.starts_with("3.") {
        format!(
            "<meta property=\"hl:metadata\">{}</meta>",
            xml::escaped(&extension)
        )
    } else {
        format!(
            "<meta name=\"{EXTENSION_NAMESPACE}\" content=\"{}\"/>",
            xml::escaped(&extension)
        )
    };
    if let Some(node) = extension_nodes.first() {
        edits.push((node.range.clone(), extension));
    } else {
        additions.push_str(&extension);
    }
    if version.starts_with("3.") {
        let modified = nodes
            .iter()
            .filter(|node| {
                node.name == "meta"
                    && node.attr("property") == Some("dcterms:modified")
                    && node.attr("refines").is_none()
            })
            .collect::<Vec<_>>();
        if modified.len() > 1 {
            return Err(io_error("Conflicting EPUB modification timestamps"));
        }
        let now = crate::comic::now_ms();
        let (year, month, day) = super::comic_info::civil_date(now.div_euclid(86_400_000));
        let seconds = now.div_euclid(1000).rem_euclid(86400);
        let timestamp = format!(
            "{year:04}-{month:02}-{day:02}T{:02}:{:02}:{:02}Z",
            seconds / 3600,
            seconds / 60 % 60,
            seconds % 60
        );
        if let Some(node) = modified.first() {
            edits.push((
                node.range.clone(),
                format!("<meta property=\"dcterms:modified\">{timestamp}</meta>"),
            ));
        } else {
            let _ = write!(
                additions,
                "<meta property=\"dcterms:modified\">{timestamp}</meta>"
            );
        }
    }
    Ok(())
}

pub(super) fn prepare_epub(
    source: &Path,
    intent: &MetadataWriteIntent,
) -> Result<PreparedLocalWrite, HentaiError> {
    let before_digest = file_digest(source)?.ok_or_else(|| io_error("EPUB source is missing"))?;
    let mut archive = ZipArchive::new(File::open(source).map_err(io_error)?).map_err(io_error)?;
    for forbidden in ["META-INF/encryption.xml", "META-INF/signatures.xml"] {
        if archive.by_name(forbidden).is_ok() {
            return Err(io_error("Protected or signed EPUB is unsupported"));
        }
    }
    let path = opf_path(&mut archive)?;
    let mut opf = String::new();
    archive
        .by_name(&path)
        .map_err(io_error)?
        .read_to_string(&mut opf)
        .map_err(io_error)?;
    let output_opf = update_opf(&opf, intent)?;
    let mut output = tempfile::Builder::new()
        .prefix(".hlwriteback-")
        .suffix(".tmp")
        .tempfile_in(
            source
                .parent()
                .ok_or_else(|| io_error("Missing EPUB parent"))?,
        )
        .map_err(io_error)?;
    let mut hashes = BTreeMap::new();
    {
        let mut writer = ZipWriter::new(output.as_file_mut());
        writer.set_raw_comment(archive.comment().into());
        let mut mimetype = String::new();
        archive
            .by_name("mimetype")
            .map_err(io_error)?
            .read_to_string(&mut mimetype)
            .map_err(io_error)?;
        if mimetype != "application/epub+zip" {
            return Err(io_error("Invalid EPUB mimetype"));
        }
        writer
            .start_file(
                "mimetype",
                SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored),
            )
            .map_err(io_error)?;
        writer.write_all(mimetype.as_bytes()).map_err(io_error)?;
        for index in 0..archive.len() {
            let mut entry = archive.by_index(index).map_err(io_error)?;
            if entry.encrypted() || entry.enclosed_name().is_none() {
                return Err(io_error("Unsafe EPUB archive member"));
            }
            let name = entry.name().to_owned();
            let digest = super::local::digest_stream(&mut entry)?;
            drop(entry);
            if hashes.insert(name.clone(), digest).is_some() {
                return Err(io_error("Duplicate EPUB member"));
            }
            if name == "mimetype" {
                continue;
            }
            if name == path {
                writer
                    .start_file(&name, SimpleFileOptions::default())
                    .map_err(io_error)?;
                writer.write_all(output_opf.as_bytes()).map_err(io_error)?;
            } else {
                writer
                    .raw_copy_file(archive.by_index(index).map_err(io_error)?)
                    .map_err(io_error)?;
            }
        }
        writer.finish().map_err(io_error)?;
    }
    output.as_file_mut().sync_all().map_err(io_error)?;
    let mut verified =
        ZipArchive::new(File::open(output.path()).map_err(io_error)?).map_err(io_error)?;
    for index in 0..verified.len() {
        let mut entry = verified.by_index(index).map_err(io_error)?;
        let name = entry.name().to_owned();
        let digest = super::local::digest_stream(&mut entry)?;
        let old = hashes.remove(&name);
        if name != path && old.as_deref() != Some(&digest) {
            return Err(io_error("EPUB member changed"));
        }
    }
    if !hashes.is_empty() || file_digest(source)?.as_deref() != Some(&before_digest) {
        return Err(io_error("EPUB source changed"));
    }
    let after_digest =
        file_digest(output.path())?.ok_or_else(|| io_error("EPUB output missing"))?;
    Ok(PreparedLocalWrite {
        target: source.to_owned(),
        temporary: output,
        before_digest: Some(before_digest),
        after_digest,
    })
}
