# app_settings

Owner of application preferences persistence, migration, and settings UI composition.

## Add or change an appearance enum preference

1. **Domain** — Update the enum / field on `AppSetting` in `domain/app_setting.dart`. Put the default in `domain/app_setting_defaults.dart` and reference it from `@Default(...)`.
2. **Migration** — If the JSON key is new or remapped, update `domain/app_setting_migration.dart` (`putIfAbsent` / remaps) using the same defaults constants. Bump `kAppSettingSchemaVersion` only when the on-disk shape needs a version gate.
3. **Codegen (Freezed / Riverpod only)** — From `app/`: `dart run build_runner build` when Freezed or `@Riverpod` inputs change. Do **not** run a full rebuild solely to refresh unrelated `theme_tailor` outputs.
4. **l10n** — Add ARB keys in `app/l10n/app_*.arb`, then `flutter gen-l10n` only (ARB-only changes). Extend the exhaustive switch in `presentation/l10n/app_settings_l10n.dart`.
5. **Schema / UI** — Register the preference in `presentation/patterns/settings/appearance_preference_schema.dart` when it is a theme/font/locale-style enum nav tile. Color dialog and dynamic-color switch stay special-cased in `settings_sections.dart`.
6. **Theme wiring** — If the preference affects assembly (e.g. font), update the mapper / `design-system` font spec and bootstrap consumers.
7. **Contracts** — Update and run:
   - `test/features/app_settings/domain/appearance_preference_schema_contract_test.dart`
   - `test/features/app_settings/domain/app_setting_migration_test.dart`
   - `test/features/app_settings/domain/app_color_scheme_contract_test.dart`
8. **Lab** — Appearance / interface / libraryBrowse / about / updates / storage use production `settingsSectionsFor` via the Widgetbook host `ProviderScope`. Reading and metadataBackup may still use Lab mocks until their providers are faked.

## Codegen noise

Do not commit unrelated `*.tailor.dart` or platform `generated_plugin_registrant.*` churn from an incidental full `build_runner` / `pub get`. Gate `codegen-drift` only requires regeneration for inputs you actually changed.
