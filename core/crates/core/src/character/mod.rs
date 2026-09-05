use crate::named_facet::{
    list_all_named_facet_names, list_distinct_named_facet_names, JunctionNamedFacet,
};
use crate::error::HentaiError;

pub fn distinct_characters_sql() -> String {
    JunctionNamedFacet::Character.distinct_attached_sql()
}

pub async fn list_all_characters() -> Result<Vec<String>, HentaiError> {
    list_all_named_facet_names(JunctionNamedFacet::Character).await
}

pub async fn list_distinct_characters(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiError> {
    list_distinct_named_facet_names(JunctionNamedFacet::Character, library_id).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn distinct_characters_sql_scopes_current_library() {
        let sql = distinct_characters_sql();
        assert!(sql.contains("comic_characters"));
        assert!(sql.contains("c.library_id = ?"));
    }
}
