use sha1::{Digest, Sha1};

fn sha1_hex(input: &str) -> String {
    let mut hasher = Sha1::new();
    hasher.update(input.as_bytes());
    format!("{:x}", hasher.finalize())
}

/// `relative_path` is the `/`-separated set folder under the Library root; empty for the root set.
pub fn image_set_id(library_id: &str, relative_path: &str) -> String {
    sha1_hex(&format!("image_set:{library_id}:{relative_path}"))
}

pub fn image_set_image_id(
    library_id: &str,
    carrier_relative_path: &str,
    member_path: &str,
) -> String {
    sha1_hex(&format!(
        "image_set_image:{library_id}:{carrier_relative_path}:{member_path}"
    ))
}

/// Opaque submission id (name may change; millis avoids collide on recreate).
pub fn image_set_submission_id(
    library_id: &str,
    image_set_id: &str,
    name: &str,
    millis: i64,
) -> String {
    sha1_hex(&format!(
        "image_set_submission:{library_id}:{image_set_id}:{millis}:{name}"
    ))
}
