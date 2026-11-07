mod common;

use std::path::Path;

use hentai_core::{
    comic_id_from_path, create_local_library, create_sync_handle, init_db_at_path, sync_library,
    trash_comics, watch_library_home_stats, HentaiError, LibraryDto, LibraryHomeStatDto,
    SyncScanMode,
};
use tempfile::TempDir;

fn write_cbz(path: &Path, pages: usize) {
    std::fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    let file = std::fs::File::create(path).expect("create cbz");
    let mut zip = zip::ZipWriter::new(file);
    let options =
        zip::write::SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored);
    use std::io::Write as _;
    for page in 0..pages {
        zip.start_file(format!("{page:03}.jpg"), options)
            .expect("start");
        zip.write_all(b"page").expect("write");
    }
    zip.finish().expect("finish");
}

fn run(test: impl FnOnce(&TempDir, &tokio::runtime::Runtime)) {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        test(&temp, &runtime);
    });
}

async fn sync(library: &LibraryDto) {
    sync_library(
        create_sync_handle(),
        SyncScanMode::Full,
        false,
        Some(library.library_id.as_str()),
        vec![],
        |_| {},
    )
    .await
    .expect("sync");
}

fn capture<T>(slot: &mut Option<T>) -> impl FnMut(T) -> Result<(), HentaiError> + '_ {
    move |value| {
        *slot = Some(value);
        Err(HentaiError::validation("stop"))
    }
}

async fn stats(exclude_r18: bool) -> Vec<LibraryHomeStatDto> {
    let mut slot = None;
    let _ = watch_library_home_stats(exclude_r18, capture(&mut slot)).await;
    slot.expect("library stats emitted")
}

fn find<'a>(rows: &'a [LibraryHomeStatDto], id: &str) -> &'a LibraryHomeStatDto {
    rows.iter()
        .find(|row| row.library_id == id)
        .unwrap_or_else(|| panic!("missing stats for {id}"))
}

#[test]
fn library_home_stats_count_visible_comics_series_and_sync_time_per_library() {
    run(|temp, runtime| {
        let root_a = temp.path().join("a");
        let solo = root_a.join("solo.cbz");
        write_cbz(&root_a.join("Series").join("a.cbz"), 1);
        write_cbz(&root_a.join("Series").join("b.cbz"), 2);
        write_cbz(&solo, 3);
        let root_b = temp.path().join("b");
        write_cbz(&root_b.join("one.cbz"), 1);

        runtime.block_on(async {
            init_db_at_path(&temp.path().join("stats.sqlite"))
                .await
                .expect("init");
            let lib_a = create_local_library(&root_a.to_string_lossy(), Some("A"))
                .await
                .expect("create a");
            let lib_b = create_local_library(&root_b.to_string_lossy(), Some("B"))
                .await
                .expect("create b");
            sync(&lib_a).await;
            sync(&lib_b).await;

            let rows = stats(false).await;
            let a = find(&rows, &lib_a.library_id);
            assert_eq!(a.comic_count, 3);
            // Series folder + standalone solo.cbz：单本也计为一个 series（与全局计数口径一致）。
            assert_eq!(a.series_count, 2);
            assert!(a.last_successful_sync_at_ms.is_some());
            let b = find(&rows, &lib_b.library_id);
            assert_eq!(b.comic_count, 1);
            assert_eq!(b.series_count, 1);

            trash_comics(vec![comic_id_from_path(&solo.to_string_lossy())])
                .await
                .expect("trash");
            let rows = stats(false).await;
            assert_eq!(find(&rows, &lib_a.library_id).comic_count, 2);
            assert_eq!(find(&rows, &lib_a.library_id).series_count, 1);

            // R18 排除分支：绑定数与子查询占位符必须一致，否则查询失败。
            let rows = stats(true).await;
            assert_eq!(find(&rows, &lib_a.library_id).comic_count, 2);
            assert_eq!(find(&rows, &lib_b.library_id).comic_count, 1);
        });
    });
}
