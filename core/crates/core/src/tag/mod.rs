//! Tag dictionary import only; Tag dictionary CRUD lives in `crate::named_facet`.

mod dictionary_import;

pub use dictionary_import::{import_tag_dictionary, TagDictionaryImportResult};
