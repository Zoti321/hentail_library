import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/shared/domain/ports/reader_settings_command_port.dart';

/// 应用设置的共享状态与端口 Provider 声明（#265）。
///
/// 只声明、不实现；默认抛 [UnimplementedError]，由 bootstrap 注入 app_settings 的实现。

/// 应用设置（同步可读形态）。
final Provider<AsyncValue<AppSetting>> appSettingsStateProvider =
    Provider<AsyncValue<AppSetting>>(
      (Ref ref) => throw UnimplementedError(
        'appSettingsStateProvider 未注入，请在 bootstrap 中 override',
      ),
    );

/// 应用设置（等待首次加载完成的 Future 形态）。
final FutureProvider<AppSetting> appSettingsFutureProvider =
    FutureProvider<AppSetting>(
      (Ref ref) => throw UnimplementedError(
        'appSettingsFutureProvider 未注入，请在 bootstrap 中 override',
      ),
    );

/// 阅读器设置写入端口。
final Provider<ReaderSettingsCommandPort> readerSettingsCommandPortProvider =
    Provider<ReaderSettingsCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'readerSettingsCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
