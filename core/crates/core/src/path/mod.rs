use crate::library::{
    create_local_library, delete_library, list_libraries, LibraryDto,
};
use crate::error::HentaiError;

pub async fn list_all_paths() -> Result<Vec<String>, HentaiError> {
    let libs = list_libraries().await?;
    Ok(libs.into_iter().map(|l| l.root_path).collect())
}

pub async fn add_path(raw_path: &str) -> Result<(), HentaiError> {
    let _ = create_local_library(raw_path).await?;
    Ok(())
}

pub async fn remove_path(raw_path: &str) -> Result<(), HentaiError> {
    let libs = list_libraries().await?;
    let target = libs.into_iter().find(|l| l.root_path == raw_path);
    if let Some(LibraryDto { library_id, .. }) = target {
        delete_library(&library_id).await?;
    }
    Ok(())
}

pub async fn watch_paths(
    mut emit: impl FnMut(Vec<String>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let mut last = crate::comic::read_data_version().await?;
    emit(list_all_paths().await?)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = crate::comic::read_data_version().await?;
        if version != last {
            last = version;
            emit(list_all_paths().await?)?;
        }
    }
}
