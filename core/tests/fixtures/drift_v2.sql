PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS comics (
  comic_id TEXT NOT NULL PRIMARY KEY,
  path TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  title TEXT NOT NULL,
  content_rating TEXT NOT NULL DEFAULT 'unknown',
  page_count INTEGER
);

CREATE TABLE IF NOT EXISTS tags (
  name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS authors (
  name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS comic_tags (
  comic_id TEXT NOT NULL,
  tag_name TEXT NOT NULL,
  PRIMARY KEY (comic_id, tag_name),
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE,
  FOREIGN KEY(tag_name) REFERENCES tags(name) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS comic_authors (
  comic_id TEXT NOT NULL,
  author_name TEXT NOT NULL,
  PRIMARY KEY (comic_id, author_name),
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE,
  FOREIGN KEY(author_name) REFERENCES authors(name) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS series (
  series_id TEXT NOT NULL PRIMARY KEY,
  folder_path TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  serialization_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (serialization_status IN ('unknown', 'ongoing', 'ended', 'hiatus')),
  total_count INTEGER NULL CHECK (total_count IS NULL OR total_count > 0)
);

CREATE TABLE IF NOT EXISTS series_items (
  series_id TEXT NOT NULL,
  comic_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  PRIMARY KEY (series_id, comic_id),
  UNIQUE(comic_id),
  FOREIGN KEY(series_id) REFERENCES series(series_id) ON DELETE CASCADE,
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS comic_thumbnails (
  comic_id TEXT NOT NULL PRIMARY KEY,
  thumbnail BLOB NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS saved_paths (
  raw_path TEXT NOT NULL PRIMARY KEY,
  security_bookmark TEXT
);

CREATE TABLE IF NOT EXISTS comic_reading_histories (
  comic_id TEXT NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  last_read_time INTEGER NOT NULL,
  page_index INTEGER
);

CREATE TABLE IF NOT EXISTS series_reading_histories (
  series_id TEXT NOT NULL PRIMARY KEY,
  last_read_comic_id TEXT NOT NULL,
  last_read_time INTEGER NOT NULL,
  page_index INTEGER,
  FOREIGN KEY(series_id) REFERENCES series(series_id) ON DELETE CASCADE
);

INSERT INTO comics (comic_id, path, resource_type, title, content_rating, page_count) VALUES
  ('86408880d30b0de95ca959feb60a3b72dcb1889b', 'C:/漫画/test.zip', 'zip', '测试漫画', 'safe', 42),
  ('af738b6b1b3bbfab9a0fd591459572509d7ef4d5', '/home/user/comics/foo.cbz', 'cbz', 'POSIX 漫画', 'unknown', 12),
  ('e931fd412112e427f7335e127af79c8b0f87887b', 'C:/漫画/子目录', 'dir', 'R18 样本', 'r18', 10);

INSERT INTO authors (name) VALUES ('作者A'), ('作者B');
INSERT INTO tags (name) VALUES ('冒险'), ('奇幻');

INSERT INTO comic_authors (comic_id, author_name) VALUES
  ('86408880d30b0de95ca959feb60a3b72dcb1889b', '作者A');

INSERT INTO comic_tags (comic_id, tag_name) VALUES
  ('86408880d30b0de95ca959feb60a3b72dcb1889b', '冒险');
