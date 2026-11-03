use hentai_core::{list_author_names_for_form, list_named_facet_for_form};

use super::types::{JunctionNamedFacetFrb, NamedFacetFormEntryFrbDto};
use crate::api::init::HentaiErrorDto;
use crate::named_facet_route::{route, NamedFacetRoute};

/// Comic metadata form candidates sorted by attachment count DESC, name ASC.
#[flutter_rust_bridge::frb]
pub async fn list_named_facet_for_form_frb(
    facet: JunctionNamedFacetFrb,
) -> Result<Vec<NamedFacetFormEntryFrbDto>, HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => list_named_facet_for_form(facet).await,
        NamedFacetRoute::Author => list_author_names_for_form().await,
    }
    .map(|rows| {
        rows.into_iter()
            .map(NamedFacetFormEntryFrbDto::from)
            .collect()
    })
    .map_err(HentaiErrorDto::from)
}
