//! Path migration：位置键变化后仍判定为同一 Comic / Series 时，把库记录 rekey 到新身份。
//!
//! 一个模块拥有整个 Path migration：配对（[`pairing`]）与落库（[`persist`]）。
//! 两个真实调用点共用本模块接口——Library sync（`sync/writer.rs`）与 Local 改根
//! （`library/mod.rs`）。语义以 ADR-0013 为准，落库不自行开启事务。

pub mod pairing;
pub(crate) mod persist;

pub use pairing::{
    comic_migration_new_paths, detect_path_migration_pairs, detect_series_path_migration_pairs,
    migrated_id_sets, ComicMigration, ComicMigrationPair, ResourceFingerprint, SeriesMigrationPair,
};

pub(crate) use persist::{apply_comic_rekeys, apply_series_rekeys};
