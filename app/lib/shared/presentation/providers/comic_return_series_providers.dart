/// 详情返回上下文供共享壳消费；comic owner 实现，组合根注入。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/application/contracts/comic_return_series_commands.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<RememberComicReturnSeriesCommand>
rememberComicReturnSeriesCommandProvider = requiredProvider(
  'rememberComicReturnSeriesCommandProvider',
);

final Provider<ClearComicReturnSeriesCommand>
clearComicReturnSeriesCommandProvider = requiredProvider(
  'clearComicReturnSeriesCommandProvider',
);
