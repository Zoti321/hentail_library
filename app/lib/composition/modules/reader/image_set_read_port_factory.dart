import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/composition/modules/reader/image_set_read_port_adapter.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/repositories/image_set_repository_impl.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';

ImageSetReadPort createImageSetReadPort(Ref ref) =>
    const ImageSetReadPortAdapter(ImageSetRepositoryImpl());
