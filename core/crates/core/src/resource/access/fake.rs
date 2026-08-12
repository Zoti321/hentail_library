use std::collections::BTreeMap;
use std::io::Cursor;

use crate::error::HentaiError;

use super::{
    system_time_to_ms, ResourceAccess, ResourceEntry, ResourceKind, ResourceStat, ResourceStream,
};
use std::time::SystemTime;

#[derive(Debug, Clone)]
enum FakeNode {
    Dir,
    File { bytes: Vec<u8>, modified_ms: i64 },
}

/// In-memory [ResourceAccess] for sync / open-stream tests without a real FS or WebDAV.
#[derive(Debug, Default, Clone)]
pub struct FakeResourceAccess {
    nodes: BTreeMap<String, FakeNode>,
}

impl FakeResourceAccess {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn insert_dir(&mut self, location: impl Into<String>) {
        let location = normalize_fake_location(location.into());
        self.ensure_ancestors(&location);
        self.nodes.insert(location, FakeNode::Dir);
    }

    pub fn insert_file(&mut self, location: impl Into<String>, bytes: impl Into<Vec<u8>>) {
        let location = normalize_fake_location(location.into());
        self.ensure_ancestors(&location);
        self.nodes.insert(
            location,
            FakeNode::File {
                bytes: bytes.into(),
                modified_ms: system_time_to_ms(SystemTime::now()),
            },
        );
    }

    pub fn set_modified_ms(&mut self, location: &str, modified_ms: i64) {
        let location = normalize_fake_location(location.to_string());
        if let Some(FakeNode::File {
            modified_ms: slot, ..
        }) = self.nodes.get_mut(&location)
        {
            *slot = modified_ms;
        }
    }

    fn ensure_ancestors(&mut self, location: &str) {
        let parts: Vec<&str> = location.split('/').filter(|p| !p.is_empty()).collect();
        if parts.len() <= 1 {
            return;
        }
        let mut acc = String::new();
        for part in &parts[..parts.len() - 1] {
            if acc.is_empty() {
                if location.starts_with('/') {
                    acc.push('/');
                }
                acc.push_str(part);
            } else {
                acc.push('/');
                acc.push_str(part);
            }
            self.nodes.entry(acc.clone()).or_insert(FakeNode::Dir);
        }
    }
}

impl ResourceAccess for FakeResourceAccess {
    fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
        let location = normalize_fake_location(location.to_string());
        match self.nodes.get(&location) {
            Some(FakeNode::Dir) => {}
            Some(FakeNode::File { .. }) => {
                return Err(HentaiError::validation(format!(
                    "目录扫描失败: {location} (not a directory)"
                )));
            }
            None => {
                return Err(HentaiError::validation(format!(
                    "目录扫描失败: {location} (missing)"
                )));
            }
        }
        let prefix = if location.ends_with('/') {
            location.clone()
        } else {
            format!("{location}/")
        };
        let mut out = Vec::new();
        for (child_loc, node) in &self.nodes {
            if !child_loc.starts_with(&prefix) {
                continue;
            }
            let rest = &child_loc[prefix.len()..];
            if rest.is_empty() || rest.contains('/') {
                continue;
            }
            let kind = match node {
                FakeNode::Dir => ResourceKind::Dir,
                FakeNode::File { .. } => ResourceKind::File,
            };
            out.push(ResourceEntry {
                name: rest.to_string(),
                location: child_loc.clone(),
                kind,
            });
        }
        out.sort_by(|a, b| a.name.cmp(&b.name));
        Ok(out)
    }

    fn stat(&self, location: &str) -> Result<Option<ResourceStat>, HentaiError> {
        let location = normalize_fake_location(location.to_string());
        Ok(match self.nodes.get(&location) {
            Some(FakeNode::Dir) => Some(ResourceStat {
                kind: ResourceKind::Dir,
                size: 0,
                modified_ms: 0,
            }),
            Some(FakeNode::File {
                bytes,
                modified_ms,
            }) => Some(ResourceStat {
                kind: ResourceKind::File,
                size: bytes.len() as u64,
                modified_ms: *modified_ms,
            }),
            None => None,
        })
    }

    fn open_stream(&self, location: &str) -> Result<ResourceStream, HentaiError> {
        let location = normalize_fake_location(location.to_string());
        match self.nodes.get(&location) {
            Some(FakeNode::File { bytes, .. }) => Ok(Box::new(Cursor::new(bytes.clone()))),
            Some(FakeNode::Dir) => Err(HentaiError::validation(format!(
                "打开失败: {location} (is a directory)"
            ))),
            None => Err(HentaiError::validation(format!(
                "打开失败: {location} (missing)"
            ))),
        }
    }
}

fn normalize_fake_location(raw: String) -> String {
    let mut s = raw.replace('\\', "/");
    while s.ends_with('/') && s.len() > 1 {
        s.pop();
    }
    s
}
