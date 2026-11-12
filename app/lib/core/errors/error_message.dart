import 'package:hentai_library/core/errors/app_exception.dart';

String appErrorMessage(Object error) =>
    error is AppException ? error.message : error.toString();
