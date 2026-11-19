use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};

use sha2::{Digest, Sha256};
use tempfile::NamedTempFile;
use zip::{write::SimpleFileOptions, ZipArchive, ZipWriter};

use super::{update_comic_info, MetadataWriteIntent};
use crate::error::HentaiError;

pub(super) struct PreparedLocalWrite {
    pub target: PathBuf,
    pub temporary: NamedTempFile,
    pub before_digest: Option<String>,
    pub after_digest: String,
}

pub(super) fn io_error(error: impl std::fmt::Display) -> HentaiError {
    HentaiError::validation(format!("Resource metadata embedding: {error}"))
}

pub(super) fn file_digest(path: &Path) -> Result<Option<String>, HentaiError> {
    let mut file = match File::open(path) {
        Ok(file) => file,
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(err) => return Err(io_error(err)),
    };
    let mut hash = Sha256::new();
    let mut buffer = vec![0_u8; 65536];
    loop {
        let count = file.read(&mut buffer).map_err(io_error)?;
        if count == 0 {
            break;
        }
        hash.update(&buffer[..count]);
    }
    Ok(Some(format!("{:x}", hash.finalize())))
}

pub(super) fn prepare(
    source: &Path,
    resource_type: &str,
    intent: &MetadataWriteIntent,
) -> Result<PreparedLocalWrite, HentaiError> {
    match resource_type {
        "dir" => prepare_directory(source, intent),
        "zip" | "cbz" => prepare_zip(source, intent),
        "sevenz" | "cb7" => prepare_sevenz(source, intent),
        "epub" => super::epub::prepare_epub(source, intent),
        "pdf" => super::pdf::prepare_pdf(source, intent),
        _ => Err(io_error(format!(
            "Unsupported writeback format: {resource_type}"
        ))),
    }
}

fn temporary(parent: &Path) -> Result<NamedTempFile, HentaiError> {
    tempfile::Builder::new()
        .prefix(".hlwriteback-")
        .suffix(".tmp")
        .tempfile_in(parent)
        .map_err(io_error)
}

fn prepare_directory(
    source: &Path,
    intent: &MetadataWriteIntent,
) -> Result<PreparedLocalWrite, HentaiError> {
    let mut matches = Vec::new();
    for entry in fs::read_dir(source).map_err(io_error)? {
        let entry = entry.map_err(io_error)?;
        if entry
            .file_name()
            .to_string_lossy()
            .eq_ignore_ascii_case("ComicInfo.xml")
        {
            if entry.file_type().map_err(io_error)?.is_symlink()
                || !entry.file_type().map_err(io_error)?.is_file()
            {
                return Err(io_error("ComicInfo must be a regular file"));
            }
            matches.push(entry.path());
        }
    }
    if matches.len() > 1 {
        return Err(io_error("Conflicting ComicInfo case variants"));
    }
    let target = matches
        .pop()
        .unwrap_or_else(|| source.join("ComicInfo.xml"));
    let before_digest = file_digest(&target)?;
    let existing = if before_digest.is_some() {
        Some(fs::read_to_string(&target).map_err(io_error)?)
    } else {
        None
    };
    let full;
    let intent = if existing.is_none() {
        full = MetadataWriteIntent::full(intent.snapshot.clone());
        &full
    } else {
        intent
    };
    let xml = update_comic_info(existing.as_deref(), intent)?;
    let mut output = temporary(
        source
            .parent()
            .ok_or_else(|| io_error("Missing resource parent"))?,
    )?;
    output.write_all(xml.as_bytes()).map_err(io_error)?;
    output.as_file_mut().sync_all().map_err(io_error)?;
    let after_digest = file_digest(output.path())?.ok_or_else(|| io_error("Output disappeared"))?;
    if file_digest(&target)? != before_digest {
        return Err(io_error("Source metadata changed while preparing output"));
    }
    Ok(PreparedLocalWrite {
        target,
        temporary: output,
        before_digest,
        after_digest,
    })
}

fn prepare_zip(
    source: &Path,
    intent: &MetadataWriteIntent,
) -> Result<PreparedLocalWrite, HentaiError> {
    let before_digest = file_digest(source)?.ok_or_else(|| io_error("Source is missing"))?;
    let mut archive = ZipArchive::new(File::open(source).map_err(io_error)?).map_err(io_error)?;
    let mut metadata_index = None;
    let mut metadata_name = "ComicInfo.xml".to_owned();
    let mut existing = None;
    let mut member_hashes = BTreeMap::new();
    for index in 0..archive.len() {
        let mut entry = archive.by_index(index).map_err(io_error)?;
        if entry.encrypted() || entry.enclosed_name().is_none() {
            return Err(io_error("Encrypted or unsafe archive entry"));
        }
        let name = entry.name().replace('\\', "/");
        if name
            .rsplit('/')
            .next()
            .is_some_and(|base| base.eq_ignore_ascii_case("ComicInfo.xml"))
        {
            if name.contains('/') || metadata_index.is_some() {
                return Err(io_error(
                    "Conflicting or nested ComicInfo; root metadata is required",
                ));
            }
            metadata_index = Some(index);
            metadata_name.clear();
            metadata_name.push_str(entry.name());
            let mut xml = String::new();
            entry.read_to_string(&mut xml).map_err(io_error)?;
            existing = Some(xml);
        } else {
            let digest = digest_stream(&mut entry)?;
            if member_hashes
                .insert(entry.name().to_owned(), digest)
                .is_some()
            {
                return Err(io_error("Duplicate archive member names"));
            }
        }
    }
    let full;
    let intent = if existing.is_none() {
        full = MetadataWriteIntent::full(intent.snapshot.clone());
        &full
    } else {
        intent
    };
    let xml = update_comic_info(existing.as_deref(), intent)?;
    let mut output = temporary(
        source
            .parent()
            .ok_or_else(|| io_error("Missing source parent"))?,
    )?;
    {
        let mut writer = ZipWriter::new(output.as_file_mut());
        writer.set_raw_comment(archive.comment().into());
        for index in 0..archive.len() {
            if Some(index) == metadata_index {
                continue;
            }
            writer
                .raw_copy_file(archive.by_index(index).map_err(io_error)?)
                .map_err(io_error)?;
        }
        writer
            .start_file(
                &metadata_name,
                SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated),
            )
            .map_err(io_error)?;
        writer.write_all(xml.as_bytes()).map_err(io_error)?;
        writer.finish().map_err(io_error)?;
    }
    output.as_file_mut().sync_all().map_err(io_error)?;
    verify_zip_metadata_output(
        output.path(),
        &metadata_name,
        &xml,
        &mut member_hashes,
        source,
        &before_digest,
    )?;
    let after_digest = file_digest(output.path())?.ok_or_else(|| io_error("Output is missing"))?;
    Ok(PreparedLocalWrite {
        target: source.to_owned(),
        temporary: output,
        before_digest: Some(before_digest),
        after_digest,
    })
}

fn verify_zip_metadata_output(
    output_path: &Path,
    metadata_name: &str,
    xml: &str,
    member_hashes: &mut BTreeMap<String, String>,
    source: &Path,
    before_digest: &str,
) -> Result<(), HentaiError> {
    let mut verified =
        ZipArchive::new(File::open(output_path).map_err(io_error)?).map_err(io_error)?;
    for index in 0..verified.len() {
        let mut entry = verified.by_index(index).map_err(io_error)?;
        if entry.name() == metadata_name {
            let mut actual = String::new();
            entry.read_to_string(&mut actual).map_err(io_error)?;
            if actual != xml {
                return Err(io_error("Metadata output mismatch"));
            }
        } else {
            let digest = digest_stream(&mut entry)?;
            if member_hashes.remove(entry.name()).as_deref() != Some(&digest) {
                return Err(io_error("Archive member changed during metadata writing"));
            }
        }
    }
    if !member_hashes.is_empty() {
        return Err(io_error("Archive members lost"));
    }
    if file_digest(source)?.as_deref() != Some(before_digest) {
        return Err(io_error("Source changed while preparing output"));
    }
    Ok(())
}

pub(super) fn digest_stream(stream: &mut impl Read) -> Result<String, HentaiError> {
    let mut hash = Sha256::new();
    let mut buffer = vec![0_u8; 65536];
    loop {
        let count = stream.read(&mut buffer).map_err(io_error)?;
        if count == 0 {
            break;
        }
        hash.update(&buffer[..count]);
    }
    Ok(format!("{:x}", hash.finalize()))
}

fn prepare_sevenz(
    source: &Path,
    intent: &MetadataWriteIntent,
) -> Result<PreparedLocalWrite, HentaiError> {
    use sevenz_rust::{Password, SevenZArchiveEntry, SevenZReader, SevenZWriter};
    let before_digest = file_digest(source)?.ok_or_else(|| io_error("Source is missing"))?;
    let mut reader = SevenZReader::open(source, Password::empty()).map_err(io_error)?;
    let mut output = temporary(
        source
            .parent()
            .ok_or_else(|| io_error("Missing source parent"))?,
    )?;
    let mut writer = SevenZWriter::new(output.as_file_mut()).map_err(io_error)?;
    let mut existing = None;
    let mut hashes = BTreeMap::new();
    reader
        .for_each_entries(|entry, data| {
            let name = entry.name().replace('\\', "/");
            if Path::new(&name).is_absolute()
                || name.split('/').any(|part| part == "..")
                || name.contains(':')
                || entry.is_anti_item()
            {
                return Err(sevenz_rust::Error::other("Unsafe 7Z member"));
            }
            if name
                .rsplit('/')
                .next()
                .is_some_and(|base| base.eq_ignore_ascii_case("ComicInfo.xml"))
            {
                if name.contains('/') || existing.is_some() {
                    return Err(sevenz_rust::Error::other("Conflicting 7Z ComicInfo"));
                }
                let mut xml = String::new();
                data.read_to_string(&mut xml)
                    .map_err(sevenz_rust::Error::io)?;
                existing = Some(xml);
            } else {
                // Stage each entry on disk rather than retaining an entire Comic in memory.
                let mut staging = tempfile::tempfile().map_err(sevenz_rust::Error::io)?;
                std::io::copy(data, &mut staging).map_err(sevenz_rust::Error::io)?;
                std::io::Seek::rewind(&mut staging).map_err(sevenz_rust::Error::io)?;
                let digest = digest_stream(&mut staging)
                    .map_err(|err| sevenz_rust::Error::other(err.message))?;
                std::io::Seek::rewind(&mut staging).map_err(sevenz_rust::Error::io)?;
                if hashes.insert(entry.name().to_owned(), digest).is_some() {
                    return Err(sevenz_rust::Error::other("Duplicate 7Z member"));
                }
                writer.push_archive_entry(entry.clone(), Some(staging))?;
            }
            Ok(true)
        })
        .map_err(io_error)?;
    let full;
    let intent = if existing.is_none() {
        full = MetadataWriteIntent::full(intent.snapshot.clone());
        &full
    } else {
        intent
    };
    let xml = update_comic_info(existing.as_deref(), intent)?;
    let mut metadata_entry = SevenZArchiveEntry::new();
    metadata_entry.name = "ComicInfo.xml".into();
    writer
        .push_archive_entry(metadata_entry, Some(xml.as_bytes()))
        .map_err(io_error)?;
    writer.finish().map_err(io_error)?;
    output.as_file_mut().sync_all().map_err(io_error)?;
    let mut verified = SevenZReader::open(output.path(), Password::empty()).map_err(io_error)?;
    verified
        .for_each_entries(|entry, data| {
            if entry.name() == "ComicInfo.xml" {
                let mut actual = String::new();
                data.read_to_string(&mut actual)
                    .map_err(sevenz_rust::Error::io)?;
                if actual != xml {
                    return Err(sevenz_rust::Error::other("7Z metadata output mismatch"));
                }
            } else {
                let digest = digest_stream(&mut data.take(u64::MAX))
                    .map_err(|err| sevenz_rust::Error::other(err.message))?;
                if hashes.remove(entry.name()).as_deref() != Some(&digest) {
                    return Err(sevenz_rust::Error::other("7Z member changed"));
                }
            }
            Ok(true)
        })
        .map_err(io_error)?;
    if !hashes.is_empty() || file_digest(source)?.as_deref() != Some(&before_digest) {
        return Err(io_error("7Z source or member contents changed"));
    }
    let after_digest = file_digest(output.path())?.ok_or_else(|| io_error("Output is missing"))?;
    Ok(PreparedLocalWrite {
        target: source.to_owned(),
        temporary: output,
        before_digest: Some(before_digest),
        after_digest,
    })
}

pub fn read_sevenz_metadata(source: &Path) -> Result<Option<super::MetadataSnapshot>, HentaiError> {
    let mut reader = sevenz_rust::SevenZReader::open(source, sevenz_rust::Password::empty())
        .map_err(io_error)?;
    let mut root = None;
    let mut nested = None;
    let mut nested_count = 0;
    reader
        .for_each_entries(|entry, data| {
            let name = entry.name().replace('\\', "/");
            if name
                .rsplit('/')
                .next()
                .is_some_and(|base| base.eq_ignore_ascii_case("ComicInfo.xml"))
            {
                let mut xml = String::new();
                data.read_to_string(&mut xml)
                    .map_err(sevenz_rust::Error::io)?;
                if name.contains('/') {
                    nested_count += 1;
                    nested = Some(xml);
                } else if root.replace(xml).is_some() {
                    return Err(sevenz_rust::Error::other("Conflicting root ComicInfo"));
                }
            }
            Ok(true)
        })
        .map_err(io_error)?;
    if root.is_none() && nested_count > 1 {
        return Err(io_error("Conflicting nested ComicInfo"));
    }
    root.or(nested)
        .map(|xml| super::read_comic_info(&xml))
        .transpose()
}
