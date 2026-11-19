//! Fallible / saturating integer conversions for SQLite and FFI boundaries.

#[must_use]
pub fn usize_to_i32(value: usize) -> i32 {
    i32::try_from(value).unwrap_or(i32::MAX)
}

#[must_use]
pub fn usize_to_u32(value: usize) -> u32 {
    u32::try_from(value).unwrap_or(u32::MAX)
}

#[must_use]
pub fn usize_to_u16(value: usize) -> u16 {
    u16::try_from(value).unwrap_or(u16::MAX)
}

#[must_use]
pub fn usize_to_f64(value: usize) -> f64 {
    f64::from(u32::try_from(value).unwrap_or(u32::MAX))
}

#[must_use]
pub fn i64_to_i32(value: i64) -> i32 {
    i32::try_from(value).unwrap_or(if value.is_negative() {
        i32::MIN
    } else {
        i32::MAX
    })
}

#[must_use]
pub fn i64_to_u32(value: i64) -> u32 {
    u32::try_from(value.max(0)).unwrap_or(u32::MAX)
}

#[must_use]
pub fn i64_to_usize(value: i64) -> usize {
    usize::try_from(value.max(0)).unwrap_or(usize::MAX)
}

#[must_use]
pub fn i64_to_u64_nonnegative(value: i64) -> u64 {
    u64::try_from(value.max(0)).unwrap_or(0)
}

#[must_use]
pub fn u64_to_i64(value: u64) -> i64 {
    i64::try_from(value).unwrap_or(i64::MAX)
}

#[must_use]
pub fn u64_to_i32(value: u64) -> i32 {
    i32::try_from(value).unwrap_or(i32::MAX)
}

#[must_use]
pub fn u64_to_usize(value: u64) -> usize {
    usize::try_from(value).unwrap_or(usize::MAX)
}

#[must_use]
pub fn u128_to_i64(value: u128) -> i64 {
    i64::try_from(value).unwrap_or(i64::MAX)
}

#[must_use]
pub fn i32_to_u64(value: i32) -> u64 {
    u64::try_from(value.max(0)).unwrap_or(0)
}

#[must_use]
pub fn i32_to_u32(value: i32) -> u32 {
    u32::try_from(value.max(0)).unwrap_or(0)
}

#[must_use]
pub fn i32_to_usize(value: i32) -> usize {
    usize::try_from(value.max(0)).unwrap_or(0)
}

#[must_use]
pub fn f64_to_i32(value: f64) -> i32 {
    if !value.is_finite() {
        return 0;
    }
    if value >= f64::from(i32::MAX) {
        return i32::MAX;
    }
    if value <= f64::from(i32::MIN) {
        return i32::MIN;
    }
    #[allow(clippy::cast_possible_truncation)]
    {
        value.trunc() as i32
    }
}

#[must_use]
pub fn u32_to_usize(value: u32) -> usize {
    usize::try_from(value).unwrap_or(usize::MAX)
}

#[must_use]
pub fn usize_to_u64(value: usize) -> u64 {
    u64::try_from(value).unwrap_or(u64::MAX)
}

#[must_use]
pub fn usize_to_i64(value: usize) -> i64 {
    i64::try_from(value).unwrap_or(i64::MAX)
}

#[must_use]
pub fn u32_to_i32(value: u32) -> i32 {
    i32::try_from(value).unwrap_or(i32::MAX)
}

#[must_use]
pub fn i64_nonneg_to_f64(value: i64) -> f64 {
    #[allow(clippy::cast_precision_loss)]
    {
        value.max(0) as f64
    }
}

#[must_use]
pub fn milliseconds_to_i64(duration_ms: u128) -> i64 {
    u128_to_i64(duration_ms)
}

#[must_use]
pub fn millis_now() -> i64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |duration| u128_to_i64(duration.as_millis()))
}
