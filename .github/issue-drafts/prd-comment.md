## Implementation slices

- #12 Monorepo: app/ and core/ layout
- #13 Rust workspace, FRB init, comicId golden
- #14 SeaORM SQLite takeover and Comic browse API
- #15 Library sync in Rust
- #16 Reader session (dir/zip/cbz/epub)
- #17 rar/7z/pdf and native vendor libs
- #18 Series inference, reading history, home counts
- #19 Retire Drift and remove auto-detect R18

Dependency: #12 -> #13 -> #14 -> (#15,#16,#18); #16 -> #17; (#15,#16,#17,#18) -> #19
