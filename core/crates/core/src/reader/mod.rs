pub mod backend;
pub mod cache;
pub mod dto;
pub mod manager;
pub mod open;
pub mod page;
pub mod prefetch;
pub mod writeback;

pub use cache::ReaderPageCacheRequest;
pub use dto::{ReaderPageDto, ReaderPageListDto};
pub use manager::{
    clear_reader_sessions, close_reader, open_reader, open_reader_with, session_path_and_type,
    with_ephemeral_reader, ReaderSessionRead,
};
pub use open::{load_page_bytes, load_page_list};
pub(crate) use page::load_page_image_bytes;
pub use page::{load_reader_page, ReaderPageRead};
pub use prefetch::{clear_reader_page_cache, prefetch_reader_pages};
pub use writeback::{writeback_after_open, writeback_with_access};
