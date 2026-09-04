use crate::named_facet::{
    list_all_named_facet_names, list_distinct_named_facet_names, JunctionNamedFacet,
};
use crate::error::HentaiError;

pub fn distinct_parodies_sql() -> String {
    JunctionNamedFacet::Parody.distinct_attached_sql()
}

pub async fn list_all_parodies() -> Result<Vec<String>, HentaiError> {
    list_all_named_facet_names(JunctionNamedFacet::Parody).await
}

pub async fn list_distinct_parodies(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiError> {
    list_distinct_named_facet_names(JunctionNamedFacet::Parody, library_id).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn distinct_parodies_sql_scopes_current_library() {
        let sql = distinct_parodies_sql();
        assert!(sql.contains("comic_parodies"));
        assert!(sql.contains("c.library_id = ?"));
    }
}
