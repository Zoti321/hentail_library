#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncLibraryPhaseDto {
    ClearingLibrary,
    Scanning,
    WritingDb,
    GeneratingThumbnails,
    Done,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncLibraryRouteDto {
    NoRootsNoop,
    NoRootsCleared,
    WithRoots,
}

#[derive(Debug, Clone, Default)]
pub struct LibrarySyncCountsDto {
    pub dir: i32,
    pub zip: i32,
    pub cbz: i32,
    pub epub: i32,
    pub cbr: i32,
    pub rar: i32,
    pub cb7: i32,
    pub sevenz: i32,
    pub pdf: i32,
}

#[derive(Debug, Clone)]
pub struct SyncLibraryProgressDto {
    pub phase: SyncLibraryPhaseDto,
    pub route: SyncLibraryRouteDto,
    pub current_path: Option<String>,
    pub accepted_total: i32,
    pub counts: LibrarySyncCountsDto,
    pub removed_count: Option<i32>,
    pub added_count: Option<i32>,
    pub kept_count: Option<i32>,
    pub thumbnail_total: Option<i32>,
    pub thumbnail_done: Option<i32>,
    pub thumbnail_failed_count: Option<i32>,
}

impl LibrarySyncCountsDto {
    pub fn bump(&mut self, resource_type: &str) {
        match resource_type {
            "dir" => self.dir += 1,
            "zip" => self.zip += 1,
            "cbz" => self.cbz += 1,
            "epub" => self.epub += 1,
            "cbr" => self.cbr += 1,
            "rar" => self.rar += 1,
            "cb7" => self.cb7 += 1,
            "sevenz" => self.sevenz += 1,
            "pdf" => self.pdf += 1,
            _ => {}
        }
    }
}
