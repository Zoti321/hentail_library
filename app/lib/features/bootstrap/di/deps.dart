// Bootstrap 组合根便利 re-export 桶（历史遗留）。
//
// 新代码请显式 import 所需符号的来源文件（如 `shared/di/data_providers.dart`、
// 各 feature 的 `di/` 或 `presentation/*.dart`），不要新增对本文件的依赖。
// 本桶仅保留仍被 bootstrap / 测试引用的 export，并逐步删减。
export 'package:hentai_library/shared/di/data_providers.dart';

export 'services.dart';

export 'package:hentai_library/features/library_admin/di/shared_state_ports.dart';
export 'package:hentai_library/features/named_metadata/presentation/metadata.dart';
export 'package:hentai_library/features/read_session/presentation/reader.dart';
export 'package:hentai_library/features/app_settings/presentation/settings.dart';
export 'package:hentai_library/features/bootstrap/presentation/view_models/aggregates.dart';
export 'package:hentai_library/features/home/presentation/view_models/history_paged_feed_controller.dart';
export 'package:hentai_library/shared/di/comic_cover_providers.dart';
export 'package:hentai_library/shared/di/library_state_providers.dart';
