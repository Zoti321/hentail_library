// 同步进度阶段
enum SyncPhase { collecting, scanning, applying }

// 扫描项类型（用于报告）
enum ScannedItemType { folder, epub, archive }

/// 内容分级（用户自定义为主）。
enum ContentRating { unknown, safe, r18 }
