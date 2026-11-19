#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let Ok(text) = std::str::from_utf8(data) else {
        return;
    };
    let names: Vec<String> = text
        .split(|c: char| c == '\0' || c == '\n')
        .map(str::to_string)
        .collect();
    let _ = hentai_core::metadata_lock::normalize_names(&names);
    let _ = hentai_core::util::compute_sort_key(text);
});
