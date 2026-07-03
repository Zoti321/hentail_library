use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

use hentai_core::series::AutoSeriesInferService;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct GoldenFixture {
    data: Vec<GoldenCase>,
}

#[derive(Debug, Deserialize)]
struct GoldenCase {
    input: Vec<String>,
    output: GoldenOutput,
}

#[derive(Debug, Deserialize)]
struct GoldenOutput {
    #[serde(rename = "seriesName")]
    series_name: String,
    index: HashMap<String, i32>,
}

fn fixture_path() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/series_inference.json")
}

#[test]
fn series_inference_golden_matches_dart() {
    let raw = fs::read_to_string(fixture_path())
        .unwrap_or_else(|e| panic!("failed to read fixture: {e}"));
    let fixture: GoldenFixture =
        serde_json::from_str(&raw).unwrap_or_else(|e| panic!("failed to parse fixture: {e}"));

    let service = AutoSeriesInferService::new();

    for (case_idx, case) in fixture.data.iter().enumerate() {
        let result = service
            .infer_series_from_titles(&case.input, 2)
            .unwrap_or_else(|| {
                panic!(
                    "case {case_idx}: expected a single inferred series, got None for input {:?}",
                    case.input
                )
            });

        assert_eq!(
            result.series_name, case.output.series_name,
            "case {case_idx}: series_name mismatch"
        );
        assert_eq!(
            result.index_by_title, case.output.index,
            "case {case_idx}: index mismatch"
        );
    }
}
