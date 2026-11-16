use super::{
    local::{file_digest, io_error, PreparedLocalWrite},
    xml, MetadataSnapshot, MetadataWriteIntent, EXTENSION_NAMESPACE,
};
use crate::{error::HentaiError, metadata_lock::ComicMetaField};
use lopdf::{dictionary, Document, IncrementalDocument, Object, Stream, StringFormat};
use std::{io::Write, path::Path};
const DC: &str = "http://purl.org/dc/elements/1.1/";
const RDF: &str = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

fn xmp(document: &Document) -> Result<Option<String>, HentaiError> {
    let catalog = document.catalog().map_err(io_error)?;
    let Ok(metadata) = catalog.get(b"Metadata") else {
        return Ok(None);
    };
    let id = metadata.as_reference().map_err(io_error)?;
    let stream = document
        .get_object(id)
        .map_err(io_error)?
        .as_stream()
        .map_err(io_error)?;
    let bytes = if stream.dict.has(b"Filter") {
        stream.decompressed_content().map_err(io_error)?
    } else {
        stream.content.clone()
    };
    String::from_utf8(bytes).map(Some).map_err(io_error)
}

fn read_xmp(raw: &str) -> Result<MetadataSnapshot, HentaiError> {
    let nodes = xml::nodes(raw)?;
    let mut snapshot = MetadataSnapshot {
        content_rating: "unknown".into(),
        ..Default::default()
    };
    for node in &nodes {
        if node.namespace != DC {
            continue;
        }
        let items = nodes
            .iter()
            .filter(|item| {
                item.namespace == RDF
                    && item.name == "li"
                    && item.range.start > node.range.start
                    && item.range.end < node.range.end
            })
            .map(|item| item.text.clone())
            .collect::<Vec<_>>();
        let first = items.first().cloned().unwrap_or_else(|| node.text.clone());
        match node.name.as_str() {
            "title" => snapshot.title = first,
            "description" => snapshot.description = Some(first),
            "creator" => snapshot.authors = if items.is_empty() { vec![first] } else { items },
            "subject" => snapshot.tags = items,
            "language" => {
                snapshot.language = Some(
                    match first.split('-').next().unwrap_or_default() {
                        "zh" => "Chinese",
                        "ja" => "Japanese",
                        "en" => "English",
                        "ko" => "Korean",
                        "es" => "Spanish",
                        _ => first.as_str(),
                    }
                    .to_owned(),
                )
            }
            _ => {}
        }
    }
    let extensions = nodes
        .iter()
        .filter(|node| node.namespace == EXTENSION_NAMESPACE && node.name == "Metadata")
        .collect::<Vec<_>>();
    if extensions.len() > 1 {
        return Err(io_error("Conflicting PDF metadata extensions"));
    }
    if let Some(extension) = extensions.first() {
        snapshot = snapshot.with_extension(&extension.text);
    }
    Ok(snapshot)
}

pub fn read_pdf_metadata(source: &Path) -> Result<Option<MetadataSnapshot>, HentaiError> {
    let document = Document::load(source).map_err(io_error)?;
    xmp(&document)?.map(|raw| read_xmp(&raw)).transpose()
}

fn update_xmp(existing: Option<&str>, intent: &MetadataWriteIntent) -> Result<String, HentaiError> {
    let empty = format!("<x:xmpmeta xmlns:x=\"adobe:ns:meta/\"><rdf:RDF xmlns:rdf=\"{RDF}\"><rdf:Description rdf:about=\"\"></rdf:Description></rdf:RDF></x:xmpmeta>");
    let raw = existing.unwrap_or(&empty);
    let nodes = xml::nodes(raw)?;
    if raw.contains("http://www.aiim.org/pdfa/") {
        return Err(io_error(
            "PDF/A metadata modification needs explicit conformance support",
        ));
    }
    let descriptions = nodes
        .iter()
        .filter(|node| {
            node.namespace == RDF
                && node.name == "Description"
                && node.attr("rdf:about").unwrap_or_default().is_empty()
        })
        .collect::<Vec<_>>();
    let description = descriptions
        .first()
        .ok_or_else(|| io_error("Missing document XMP description"))?;
    let mut edits = Vec::new();
    let mut additions = String::new();
    for field in &intent.fields {
        let (name, values, array) = match field {
            ComicMetaField::Title => ("title", vec![intent.snapshot.title.clone()], "Alt"),
            ComicMetaField::Description => (
                "description",
                intent.snapshot.description.clone().into_iter().collect(),
                "Alt",
            ),
            ComicMetaField::Authors => ("creator", intent.snapshot.authors.clone(), "Seq"),
            ComicMetaField::Tags => ("subject", intent.snapshot.tags.clone(), "Bag"),
            ComicMetaField::Languages => (
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
                "Bag",
            ),
            _ => continue,
        };
        if descriptions.iter().any(|node| {
            node.attributes
                .iter()
                .any(|(key, _)| key == &format!("dc:{name}"))
        }) {
            return Err(io_error(
                "Attribute-form XMP property cannot be safely replaced",
            ));
        }
        let existing = nodes
            .iter()
            .filter(|node| {
                node.namespace == DC
                    && node.name == name
                    && descriptions.iter().any(|parent| {
                        node.depth == parent.depth + 1
                            && node.range.start > parent.range.start
                            && node.range.end < parent.range.end
                    })
            })
            .collect::<Vec<_>>();
        if existing.len() > 1 {
            return Err(io_error("Conflicting document XMP properties"));
        }
        let items = values
            .iter()
            .map(|value| {
                format!(
                    "<rdf:li{}>{}</rdf:li>",
                    if array == "Alt" {
                        " xml:lang=\"x-default\""
                    } else {
                        ""
                    },
                    xml::escaped(value)
                )
            })
            .collect::<String>();
        let element = format!("<dc:{name} xmlns:dc=\"{DC}\" xmlns:rdf=\"{RDF}\"><rdf:{array}>{items}</rdf:{array}></dc:{name}>");
        if let Some(node) = existing.first() {
            edits.push((node.range.clone(), element));
        } else {
            additions.push_str(&element);
        }
    }
    let extensions = nodes
        .iter()
        .filter(|node| node.namespace == EXTENSION_NAMESPACE && node.name == "Metadata")
        .collect::<Vec<_>>();
    if extensions.len() > 1 {
        return Err(io_error("Conflicting PDF extension"));
    }
    let extension = intent.extension_json(extensions.first().map(|node| node.text.as_str()))?;
    let element = format!(
        "<hl:Metadata xmlns:hl=\"{EXTENSION_NAMESPACE}\">{}</hl:Metadata>",
        xml::escaped(&extension)
    );
    if let Some(node) = extensions.first() {
        edits.push((node.range.clone(), element));
    } else {
        additions.push_str(&element);
    }
    if description.empty {
        let opening = &raw[description.range.start..description.range.end - 2];
        edits.push((
            description.range.clone(),
            format!("{opening}>{additions}</rdf:Description>"),
        ));
    } else {
        edits.push((description.content.end..description.content.end, additions));
    }
    xml::replace(raw, edits)
}

pub(super) fn prepare_pdf(
    source: &Path,
    intent: &MetadataWriteIntent,
) -> Result<PreparedLocalWrite, HentaiError> {
    let before_digest = file_digest(source)?.ok_or_else(|| io_error("PDF source missing"))?;
    let bytes = std::fs::read(source).map_err(io_error)?;
    let document = Document::load_mem(&bytes).map_err(io_error)?;
    if document.trailer.has(b"Encrypt")
        || document.objects.values().any(|object| {
            object.as_dict().is_ok_and(|dict| {
                dict.has(b"ByteRange")
                    || dict
                        .get(b"Type")
                        .and_then(Object::as_name)
                        .is_ok_and(|name| name == b"Sig")
            })
        })
    {
        return Err(io_error(
            "Signed or encrypted PDF cannot be safely modified",
        ));
    }
    let existing = xmp(&document)?;
    let full;
    let intent = if existing.is_none() {
        full = MetadataWriteIntent::full(intent.snapshot.clone());
        &full
    } else {
        intent
    };
    let metadata = update_xmp(existing.as_deref(), intent)?;
    let root = document
        .trailer
        .get(b"Root")
        .and_then(Object::as_reference)
        .map_err(io_error)?;
    let info = document
        .trailer
        .get(b"Info")
        .and_then(Object::as_reference)
        .ok();
    let pages = document.get_pages();
    let mut incremental = IncrementalDocument::create_from(bytes.clone(), document);
    incremental
        .opt_clone_object_to_new_document(root)
        .map_err(io_error)?;
    let metadata_id = incremental.new_document.add_object(Stream::new(
        dictionary! { "Type" => "Metadata", "Subtype" => "XML" },
        metadata.into_bytes(),
    ));
    incremental
        .new_document
        .get_object_mut(root)
        .map_err(io_error)?
        .as_dict_mut()
        .map_err(io_error)?
        .set("Metadata", metadata_id);
    let info_id = if let Some(info) = info {
        incremental
            .opt_clone_object_to_new_document(info)
            .map_err(io_error)?;
        info
    } else {
        let id = incremental
            .new_document
            .add_object(lopdf::Dictionary::new());
        incremental.new_document.trailer.set("Info", id);
        id
    };
    let info_dict = incremental
        .new_document
        .get_object_mut(info_id)
        .map_err(io_error)?
        .as_dict_mut()
        .map_err(io_error)?;
    for field in &intent.fields {
        let (name, value) = match field {
            ComicMetaField::Title => ("Title", intent.snapshot.title.clone()),
            ComicMetaField::Description => (
                "Subject",
                intent.snapshot.description.clone().unwrap_or_default(),
            ),
            ComicMetaField::Authors => ("Author", intent.snapshot.authors.join(", ")),
            ComicMetaField::Tags => ("Keywords", intent.snapshot.tags.join(", ")),
            _ => continue,
        };
        let mut bytes = vec![0xfe, 0xff];
        for unit in value.encode_utf16() {
            bytes.extend_from_slice(&unit.to_be_bytes());
        }
        info_dict.set(name, Object::String(bytes, StringFormat::Hexadecimal));
    }
    let mut output = tempfile::Builder::new()
        .prefix(".hlwriteback-")
        .suffix(".tmp")
        .tempfile_in(
            source
                .parent()
                .ok_or_else(|| io_error("Missing PDF parent"))?,
        )
        .map_err(io_error)?;
    incremental
        .save_to(output.as_file_mut())
        .map_err(io_error)?;
    output.as_file_mut().flush().map_err(io_error)?;
    output.as_file_mut().sync_all().map_err(io_error)?;
    let written = std::fs::read(output.path()).map_err(io_error)?;
    if !written.starts_with(&bytes) {
        return Err(io_error(
            "PDF incremental write did not preserve original bytes",
        ));
    }
    let verified = Document::load_mem(&written).map_err(io_error)?;
    if verified.get_pages() != pages {
        return Err(io_error("PDF page tree changed"));
    }
    for id in pages.values() {
        if verified.get_page_content(*id) != incremental.get_prev_documents().get_page_content(*id)
        {
            return Err(io_error("PDF content changed"));
        }
    }
    if file_digest(source)?.as_deref() != Some(&before_digest) {
        return Err(io_error("PDF source changed"));
    }
    let after_digest = file_digest(output.path())?.ok_or_else(|| io_error("PDF output missing"))?;
    Ok(PreparedLocalWrite {
        target: source.to_owned(),
        temporary: output,
        before_digest: Some(before_digest),
        after_digest,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fixture(path: &Path, signed: bool) {
        let mut document = Document::with_version("1.4");
        let pages = document.new_object_id();
        let content = document.add_object(Stream::new(dictionary! {}, b"q\nQ\n".to_vec()));
        let page = document.add_object(dictionary! {"Type" => "Page", "Parent" => pages, "Contents" => content, "MediaBox" => vec![0.into(),0.into(),100.into(),100.into()]});
        document.objects.insert(
            pages,
            Object::Dictionary(
                dictionary! {"Type" => "Pages", "Kids" => vec![page.into()], "Count" => 1},
            ),
        );
        let root = document.add_object(dictionary! {"Type" => "Catalog", "Pages" => pages});
        document.trailer.set("Root", root);
        if signed {
            document.add_object(dictionary! {"Type" => "Sig", "ByteRange" => vec![0.into(), 1.into(), 2.into(), 3.into()]});
        }
        document.save(path).unwrap();
    }

    #[test]
    fn pdf_incremental_embedding_preserves_original_bytes_and_roundtrips_exact_values() {
        let temp = tempfile::TempDir::new().unwrap().keep();
        let path = temp.join("book.pdf");
        fixture(&path, false);
        let original = std::fs::read(&path).unwrap();
        let snapshot = MetadataSnapshot {
            title: "标题 &".into(),
            authors: vec!["A,B".into()],
            language: Some("Esperanto".into()),
            content_rating: "safe".into(),
            tags: vec!["Tag".into()],
            parodies: vec!["IP".into()],
            published_at: Some(1_700_000_000_123),
            ..Default::default()
        };
        let prepared = prepare_pdf(&path, &MetadataWriteIntent::full(snapshot.clone())).unwrap();
        assert!(std::fs::read(prepared.temporary.path())
            .unwrap()
            .starts_with(&original));
        let imported = read_pdf_metadata(prepared.temporary.path())
            .unwrap()
            .unwrap();
        assert_eq!(imported, snapshot);
        assert_eq!(std::fs::read(&path).unwrap(), original);
    }

    #[test]
    fn signed_pdf_refuses_embedding_without_touching_original() {
        let temp = tempfile::TempDir::new().unwrap().keep();
        let path = temp.join("signed.pdf");
        fixture(&path, true);
        let original = std::fs::read(&path).unwrap();
        assert!(prepare_pdf(
            &path,
            &MetadataWriteIntent::full(MetadataSnapshot::default())
        )
        .is_err());
        assert_eq!(std::fs::read(&path).unwrap(), original);
    }
}
