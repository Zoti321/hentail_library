//! Comic trash visibility predicate (ADR-0023).
//!
//! Every browse-facing Comic query (catalog, Home, search, Series members and
//! counts, reading history, metadata aggregates) must filter through these
//! helpers so a trashed Comic never resurfaces somewhere.

/// `{alias}.deleted_at IS NULL` for queries that already select from `comics {alias}`.
pub fn visible_comic_sql(alias: &str) -> String {
    format!("{alias}.deleted_at IS NULL")
}

/// Correlated `EXISTS` for tables keyed by `comic_id` that do not join `comics`
/// (`series_items`, `comic_reading_histories`, junction tables, …).
pub fn visible_comic_id_sql(comic_id_expr: &str) -> String {
    format!(
        "EXISTS (SELECT 1 FROM comics vis_c \
         WHERE vis_c.comic_id = {comic_id_expr} AND vis_c.deleted_at IS NULL)"
    )
}

/// Negated trash check for tables whose rows may outlive their Comic row
/// (reading history keeps showing orphan rows; only trashed Comics are hidden).
pub fn comic_id_not_trashed_sql(comic_id_expr: &str) -> String {
    format!(
        "NOT EXISTS (SELECT 1 FROM comics trash_c \
         WHERE trash_c.comic_id = {comic_id_expr} AND trash_c.deleted_at IS NOT NULL)"
    )
}

/// Series has at least one visible member (Series records keep trashed members).
pub fn series_has_visible_member_sql(series_id_expr: &str) -> String {
    format!(
        "EXISTS (SELECT 1 FROM series_items vis_si \
         WHERE vis_si.series_id = {series_id_expr} AND {})",
        visible_comic_id_sql("vis_si.comic_id")
    )
}

/// Series is browsable: it has no members at all, or at least one visible member.
/// Series whose members are all trashed stay in the DB but are hidden.
pub fn series_browsable_sql(series_id_expr: &str) -> String {
    format!(
        "(NOT EXISTS (SELECT 1 FROM series_items any_si WHERE any_si.series_id = {series_id_expr}) \
         OR {})",
        series_has_visible_member_sql(series_id_expr)
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn series_predicate_nests_comic_predicate() {
        let sql = series_has_visible_member_sql("s.series_id");
        assert!(sql.contains("vis_si.series_id = s.series_id"));
        assert!(sql.contains("vis_c.comic_id = vis_si.comic_id"));
        assert!(sql.contains("vis_c.deleted_at IS NULL"));
    }
}
