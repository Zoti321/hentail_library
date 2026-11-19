#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

use std::path::{Path, PathBuf};

use hentai_core::resource::{
    parse_file, parse_file_with, parse_pdf, parse_rar_archive, parse_sevenz_archive,
    FakeResourceAccess, ResourceAccess, ResourceEntry, ResourceKind, ResourceStat, ResourceStream,
};
use hentai_core::{HentaiError, HentaiErrorCode};

struct FormatFixture {
    extension: &'static str,
    resource_type: &'static str,
    bytes: Vec<u8>,
    pages: i32,
}

fn pdf_bytes(metadata: &str, pages: i32) -> Vec<u8> {
    let kids = if pages == 0 { "" } else { "3 0 R" };
    let objects = [
        "<< /Type /Catalog /Pages 2 0 R >>".to_string(),
        format!("<< /Type /Pages /Kids [{kids}] /Count {pages} >>"),
        "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>".to_string(),
        format!("<< {metadata} >>"),
    ];
    let mut pdf = String::from("%PDF-1.4\n");
    let mut offsets = Vec::new();
    for (index, object) in objects.iter().enumerate() {
        offsets.push(pdf.len());
        pdf.push_str(&format!("{} 0 obj\n{object}\nendobj\n", index + 1));
    }
    let xref = pdf.len();
    pdf.push_str("xref\n0 5\n0000000000 65535 f \n");
    for offset in offsets {
        pdf.push_str(&format!("{offset:010} 00000 n \n"));
    }
    pdf.push_str(&format!(
        "trailer\n<< /Size 5 /Root 1 0 R /Info 4 0 R >>\nstartxref\n{xref}\n%%EOF\n"
    ));
    pdf.into_bytes()
}

fn formats() -> Vec<FormatFixture> {
    let fixtures = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/comics");
    let rar = std::fs::read(fixtures.join("sample-rar4.rar")).unwrap();
    // Retain generated fixture directories; recursive cleanup is prohibited.
    let root = tempfile::tempdir().unwrap().keep();
    let pages = root.join("pages");
    std::fs::create_dir(&pages).unwrap();
    std::fs::write(pages.join("001.jpg"), b"page-one").unwrap();
    std::fs::write(pages.join("002.jpg"), b"page-two").unwrap();
    let archive = root.join("source.7z");
    sevenz_rust::compress_to_path(&pages, &archive).unwrap();
    let sevenz = std::fs::read(archive).unwrap();
    vec![
        FormatFixture {
            extension: "rar",
            resource_type: "rar",
            bytes: rar.clone(),
            pages: 2,
        },
        FormatFixture {
            extension: "cbr",
            resource_type: "cbr",
            bytes: rar,
            pages: 2,
        },
        FormatFixture {
            extension: "7z",
            resource_type: "sevenz",
            bytes: sevenz.clone(),
            pages: 2,
        },
        FormatFixture {
            extension: "cb7",
            resource_type: "cb7",
            bytes: sevenz,
            pages: 2,
        },
        FormatFixture {
            extension: "pdf",
            resource_type: "pdf",
            bytes: pdf_bytes("", 1),
            pages: 1,
        },
    ]
}

#[test]
fn path_bound_parse_consumes_streams_at_locations_without_http_prefixes() {
    for fixture in formats() {
        let location = format!("/memory/Original title.{}", fixture.extension);
        let size = hentai_core::util::usize_to_i64(fixture.bytes.len());
        let mut access = FakeResourceAccess::new();
        access.insert_file(&location, fixture.bytes);
        let parsed = parse_file_with(&access, &location).unwrap().unwrap();
        assert_eq!(parsed.path, location);
        assert_eq!(parsed.title, "Original title");
        assert_eq!(parsed.resource_type, fixture.resource_type);
        assert_eq!(parsed.page_count, fixture.pages);
        assert_eq!(parsed.resource_size, size);
    }
}

#[test]
fn path_bound_parse_keeps_remote_titles_and_identity_out_of_temporary_paths() {
    for fixture in formats() {
        let location = format!(
            "https://nas.example/dav/Original title.{}",
            fixture.extension
        );
        let mut access = FakeResourceAccess::new();
        access.insert_file(&location, fixture.bytes);
        let parsed = parse_file_with(&access, &location).unwrap().unwrap();
        assert_eq!(parsed.path, location);
        assert_eq!(parsed.title, "Original title");
        assert_eq!(parsed.resource_type, fixture.resource_type);
        assert_eq!(parsed.page_count, fixture.pages);
    }
}

#[test]
fn path_bound_local_entry_points_preserve_source_metadata() {
    let root = tempfile::tempdir().unwrap().keep();
    for fixture in formats() {
        let path = root.join(format!("Original title.{}", fixture.extension));
        std::fs::write(&path, &fixture.bytes).unwrap();
        let direct = match fixture.resource_type {
            "rar" | "cbr" => parse_rar_archive(&path, fixture.resource_type),
            "sevenz" | "cb7" => parse_sevenz_archive(&path, fixture.resource_type),
            "pdf" => parse_pdf(&path),
            other => panic!("unexpected fixture: {other}"),
        }
        .unwrap()
        .unwrap();
        let dispatched = parse_file(&path).unwrap().unwrap();
        for parsed in [direct, dispatched] {
            assert_eq!(parsed.path, path.to_string_lossy());
            assert_eq!(parsed.title, "Original title");
            assert_eq!(parsed.page_count, fixture.pages);
            assert_eq!(parsed.resource_type, fixture.resource_type);
            assert_eq!(
                parsed.resource_size,
                hentai_core::util::usize_to_i64(fixture.bytes.len())
            );
        }
    }
}

struct MappedAccess {
    stream: FakeResourceAccess,
    physical: Option<PathBuf>,
    stat: Result<Option<ResourceStat>, HentaiError>,
}

impl ResourceAccess for MappedAccess {
    fn local_path(&self, _: &str) -> Option<PathBuf> {
        self.physical.clone()
    }

    fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
        self.stream.list(location)
    }

    fn stat(&self, _: &str) -> Result<Option<ResourceStat>, HentaiError> {
        self.stat.clone()
    }

    fn open_stream(&self, location: &str) -> Result<ResourceStream, HentaiError> {
        self.stream.open_stream(location)
    }
}

#[test]
fn path_bound_parse_uses_adapter_local_paths_and_source_stats() {
    let root = tempfile::tempdir().unwrap().keep();
    for fixture in formats() {
        let location = format!(
            "https://logical.example/Original title.{}",
            fixture.extension
        );
        let physical = root.join(format!("physical-name.{}", fixture.extension));
        std::fs::write(&physical, &fixture.bytes).unwrap();
        let mut stream = FakeResourceAccess::new();
        stream.insert_file(&location, fixture.bytes);
        let mut stat = stream.stat(&location).unwrap().unwrap();
        stat.size += 7;
        stream.set_unreachable("local capability must not open a stream");
        let access = MappedAccess {
            stream,
            physical: Some(physical),
            stat: Ok(Some(stat.clone())),
        };
        let parsed = parse_file_with(&access, &location).unwrap().unwrap();
        assert_eq!(parsed.path, location);
        assert_eq!(parsed.title, "Original title");
        assert_eq!(parsed.page_count, fixture.pages);
        assert_eq!(parsed.resource_size, hentai_core::util::u64_to_i64(stat.size));
    }
}

#[test]
fn path_bound_parse_preserves_access_errors_at_locations_without_http_prefixes() {
    let mut access = FakeResourceAccess::new();
    access.set_unreachable("401 auth rejected");
    for extension in ["rar", "cbr", "7z", "cb7", "pdf"] {
        let error = parse_file_with(&access, &format!("/memory/book.{extension}")).unwrap_err();
        assert_eq!(error.code, HentaiErrorCode::RemoteAuthFailed);
        assert_eq!(error.message, "401 auth rejected");
    }
}

#[test]
fn path_bound_parse_does_not_substitute_temporary_file_stats_for_source_stats() {
    for fixture in formats() {
        let location = format!("https://nas.example/Original title.{}", fixture.extension);
        let mut stream = FakeResourceAccess::new();
        stream.insert_file(&location, fixture.bytes);
        let mut access = MappedAccess {
            stream,
            physical: None,
            stat: Ok(None),
        };
        assert!(parse_file_with(&access, &location).unwrap().is_none());
        access.stat = Ok(Some(ResourceStat {
            kind: ResourceKind::Dir,
            size: 0,
            modified_ms: 1,
        }));
        assert!(parse_file_with(&access, &location).unwrap().is_none());
        access.stat = Err(HentaiError::remote_tls_failed("source stat rejected"));
        let error = parse_file_with(&access, &location).unwrap_err();
        assert_eq!(error.code, HentaiErrorCode::RemoteTlsFailed);
        assert_eq!(error.message, "source stat rejected");
    }
}

#[test]
fn path_bound_pdf_retains_embedded_metadata_and_empty_document_behavior() {
    let location = "https://nas.example/Fallback title.pdf";
    let mut access = FakeResourceAccess::new();
    access.insert_file(location, pdf_bytes("/Title (Embedded title) /Author (A; B) /Subject (Summary) /CreationDate (D:20240101000000)", 1));
    let parsed = parse_file_with(&access, location).unwrap().unwrap();
    assert_eq!(parsed.title, "Embedded title");
    assert_eq!(parsed.authors, ["A", "B"]);
    assert_eq!(parsed.description.as_deref(), Some("Summary"));
    assert_eq!(parsed.published_at, Some(1_704_067_200_000));
    access.insert_file(location, pdf_bytes("", 0));
    assert!(parse_file_with(&access, location).unwrap().is_none());
}
