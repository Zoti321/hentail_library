use crate::metadata_lock::{ComicMetaField, SeriesMetaField};

/// Which Comic Metadata fields a user-meta write touched; every touched field gets locked
/// (ADR-0007). Built from the field table, so a field added there cannot be forgotten here.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct ComicAutoLocks {
    flags: [bool; ComicMetaField::ALL.len()],
}

impl ComicAutoLocks {
    /// `written` answers "was this field part of the write?".
    pub fn from_written(written: impl Fn(ComicMetaField) -> bool) -> Self {
        let mut flags = [false; ComicMetaField::ALL.len()];
        for (slot, field) in ComicMetaField::ALL.iter().enumerate() {
            flags[slot] = written(*field);
        }
        Self { flags }
    }

    pub fn get(self, field: ComicMetaField) -> bool {
        self.flags[field.index()]
    }

    /// Written fields, in field-table order.
    pub fn written(self) -> Vec<ComicMetaField> {
        ComicMetaField::ALL
            .iter()
            .copied()
            .filter(|field| self.get(*field))
            .collect()
    }

    pub fn any(self) -> bool {
        self.flags.iter().any(|flag| *flag)
    }
}

/// Which Series Metadata fields a user-meta write touched; every touched field gets locked
/// (ADR-0007).
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct SeriesAutoLocks {
    flags: [bool; SeriesMetaField::ALL.len()],
}

impl SeriesAutoLocks {
    /// `written` answers "was this field part of the write?".
    pub fn from_written(written: impl Fn(SeriesMetaField) -> bool) -> Self {
        let mut flags = [false; SeriesMetaField::ALL.len()];
        for (slot, field) in SeriesMetaField::ALL.iter().enumerate() {
            flags[slot] = written(*field);
        }
        Self { flags }
    }

    pub fn get(self, field: SeriesMetaField) -> bool {
        self.flags[field.index()]
    }

    /// Written fields, in field-table order.
    pub fn written(self) -> Vec<SeriesMetaField> {
        SeriesMetaField::ALL
            .iter()
            .copied()
            .filter(|field| self.get(*field))
            .collect()
    }

    pub fn any(self) -> bool {
        self.flags.iter().any(|flag| *flag)
    }
}

/// Named-argument form of [`SeriesAutoLocks::from_written`] for the Series user-meta write.
pub fn series_auto_locks(
    name: bool,
    serialization_status: bool,
    total_count: bool,
) -> SeriesAutoLocks {
    SeriesAutoLocks::from_written(|field| match field {
        SeriesMetaField::Name => name,
        SeriesMetaField::SerializationStatus => serialization_status,
        SeriesMetaField::TotalCount => total_count,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn comic_auto_locks_round_trip_every_field() {
        for field in ComicMetaField::ALL {
            let locks = ComicAutoLocks::from_written(|candidate| candidate == field);
            assert_eq!(locks.written(), vec![field]);
            assert!(locks.any());
            assert!(locks.get(field));
        }

        let none = ComicAutoLocks::from_written(|_| false);
        assert_eq!(none, ComicAutoLocks::default());
        assert!(!none.any());
        assert!(none.written().is_empty());

        let all = ComicAutoLocks::from_written(|_| true);
        assert_eq!(all.written(), ComicMetaField::ALL.to_vec());
    }

    #[test]
    fn series_auto_locks_round_trip_every_field() {
        for field in SeriesMetaField::ALL {
            let locks = SeriesAutoLocks::from_written(|candidate| candidate == field);
            assert_eq!(locks.written(), vec![field]);
            assert!(locks.any());
        }

        assert!(SeriesAutoLocks::from_written(|_| false)
            .written()
            .is_empty());
        assert_eq!(
            series_auto_locks(true, false, false).written(),
            vec![SeriesMetaField::Name]
        );
        assert_eq!(
            series_auto_locks(false, true, false).written(),
            vec![SeriesMetaField::SerializationStatus]
        );
        assert_eq!(
            series_auto_locks(false, false, true).written(),
            vec![SeriesMetaField::TotalCount]
        );
        assert!(!series_auto_locks(false, false, false).any());
    }
}
