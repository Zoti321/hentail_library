import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/app_setting.dart';

/// Maps persisted language preference to [MaterialApp.locale].
///
/// `null` means follow the device locale list (Flutter resolution).
Locale? localeFromPreference(AppLocalePreference preference) {
  switch (preference) {
    case AppLocalePreference.system:
      return null;
    case AppLocalePreference.zhCn:
      return const Locale('zh');
    case AppLocalePreference.en:
      return const Locale('en');
  }
}
