use std::fs::{self, File, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock};

const MAX_FILE_SIZE_BYTES: u64 = 5 * 1024 * 1024;
const MAX_BACKUP_FILES: usize = 3;
const LOG_FILE_NAME: &str = "rust_log.txt";

static LOG_FILE: OnceLock<Arc<Mutex<Option<File>>>> = OnceLock::new();

pub fn log_file_slot() -> &'static Arc<Mutex<Option<File>>> {
    LOG_FILE.get_or_init(|| Arc::new(Mutex::new(None)))
}

pub fn open_log_file(app_data_dir: &str) -> io::Result<PathBuf> {
    let logs_dir = PathBuf::from(app_data_dir.trim()).join("logs");
    fs::create_dir_all(&logs_dir)?;
    let log_path = logs_dir.join(LOG_FILE_NAME);
    rotate_if_needed(&log_path)?;
    prune_old_backups(&logs_dir)?;
    let file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_path)?;
    *log_file_slot().lock().map_err(|e| io::Error::other(e.to_string()))? = Some(file);
    Ok(log_path)
}

fn rotate_if_needed(log_path: &Path) -> io::Result<()> {
    if !log_path.exists() {
        return Ok(());
    }
    if log_path.metadata()?.len() <= MAX_FILE_SIZE_BYTES {
        return Ok(());
    }
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0);
    let backup_path = log_path.with_file_name(format!("rust_log_{timestamp}.bak"));
    fs::rename(log_path, backup_path)?;
    Ok(())
}

fn prune_old_backups(logs_dir: &Path) -> io::Result<()> {
    let mut backups = Vec::new();
    for entry in fs::read_dir(logs_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file()
            && path
                .file_name()
                .and_then(|name| name.to_str())
                .is_some_and(|name| name.starts_with("rust_log_") && name.ends_with(".bak"))
        {
            backups.push(path);
        }
    }
    if backups.len() <= MAX_BACKUP_FILES {
        return Ok(());
    }
    backups.sort_by_key(|path| {
        fs::metadata(path)
            .and_then(|meta| meta.modified())
            .unwrap_or(std::time::SystemTime::UNIX_EPOCH)
    });
    for path in backups.iter().take(backups.len() - MAX_BACKUP_FILES) {
        let _ = fs::remove_file(path);
    }
    Ok(())
}

#[derive(Clone)]
pub struct SharedLogFileWriter(Arc<Mutex<Option<File>>>);

impl SharedLogFileWriter {
    pub fn from_slot() -> Self {
        Self(log_file_slot().clone())
    }
}

impl Write for SharedLogFileWriter {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        let mut guard = self
            .0
            .lock()
            .map_err(|e| io::Error::other(e.to_string()))?;
        match guard.as_mut() {
            Some(file) => file.write(buf),
            None => Ok(buf.len()),
        }
    }

    fn flush(&mut self) -> io::Result<()> {
        let mut guard = self
            .0
            .lock()
            .map_err(|e| io::Error::other(e.to_string()))?;
        if let Some(file) = guard.as_mut() {
            file.flush()?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rotate_when_file_exceeds_limit() {
        let dir = tempfile::tempdir().expect("tempdir");
        let log_path = dir.path().join(LOG_FILE_NAME);
        let mut file = File::create(&log_path).expect("create");
        let payload = vec![b'x'; (MAX_FILE_SIZE_BYTES + 1) as usize];
        file.write_all(&payload).expect("write");
        drop(file);

        rotate_if_needed(&log_path).expect("rotate");
        assert!(!log_path.exists());
        let backup_count = fs::read_dir(dir.path())
            .expect("read_dir")
            .filter_map(Result::ok)
            .filter(|entry| {
                entry
                    .path()
                    .extension()
                    .is_some_and(|ext| ext == "bak")
            })
            .count();
        assert_eq!(backup_count, 1);
    }
}
