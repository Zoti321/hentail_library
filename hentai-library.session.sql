SELECT c.title, ch.image_dir, t.name, t.type,t.is_r18
FROM comics c
LEFT JOIN chapters ch ON ch.comic_id = c.comic_id 
LEFT JOIN comic_tags ct ON ct.comic_id = c.comic_id
LEFT JOIN category_tags t ON t.id = ct.tag_id