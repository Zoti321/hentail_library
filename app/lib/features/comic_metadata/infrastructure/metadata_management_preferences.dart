import 'package:shared_preferences/shared_preferences.dart';

const String _mergeConfirmSkipKey = 'metadata_merge_confirm_skip';

Future<bool> loadMergeConfirmationSkipped() async =>
    (await SharedPreferences.getInstance()).getBool(_mergeConfirmSkipKey) ??
    false;

Future<void> saveMergeConfirmationSkipped(bool value) async {
  await (await SharedPreferences.getInstance()).setBool(
    _mergeConfirmSkipKey,
    value,
  );
}
