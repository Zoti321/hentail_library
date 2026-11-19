#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let Ok(text) = std::str::from_utf8(data) else {
        return;
    };
    let _ = hentai_core::resource_metadata::container_package_path(text);
    let _ = hentai_core::resource_metadata::read_opf(text);
});
