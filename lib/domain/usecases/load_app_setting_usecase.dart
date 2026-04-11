import '../entity/entities.dart';
import '../repository/app_setting_repo.dart';

class LoadAppSettingUsecase {
  final AppSettingRepository _repository;

  LoadAppSettingUsecase(this._repository);

  Future<AppSetting> call() async {
    return await _repository.load();
  }
}
