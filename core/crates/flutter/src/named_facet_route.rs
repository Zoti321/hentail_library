//! FRB-side routing for Named metadata facet kinds.
//!
//! Lives outside `api/` so FRB codegen does not scan these helpers. Author is routed to
//! the Author entry points; the core named-facet module only sees dictionary facets.

use hentai_core::JunctionNamedFacet;

use crate::api::named_facet::JunctionNamedFacetFrb;

/// Which core entry point serves a given FRB facet kind.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum NamedFacetRoute {
    Dictionary(JunctionNamedFacet),
    Author,
}

pub(crate) fn route(facet: JunctionNamedFacetFrb) -> NamedFacetRoute {
    match facet {
        JunctionNamedFacetFrb::Tag => NamedFacetRoute::Dictionary(JunctionNamedFacet::Tag),
        JunctionNamedFacetFrb::Parody => NamedFacetRoute::Dictionary(JunctionNamedFacet::Parody),
        JunctionNamedFacetFrb::Character => {
            NamedFacetRoute::Dictionary(JunctionNamedFacet::Character)
        }
        JunctionNamedFacetFrb::Author => NamedFacetRoute::Author,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn author_frb_kind_routes_to_author_entry_points() {
        assert_eq!(
            route(JunctionNamedFacetFrb::Author),
            NamedFacetRoute::Author
        );
        assert_eq!(
            route(JunctionNamedFacetFrb::Tag),
            NamedFacetRoute::Dictionary(JunctionNamedFacet::Tag)
        );
    }
}
