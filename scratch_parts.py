import io

base = 'lib/features/metadata_backup/presentation/widgets/'
src = base + 'metadata_import_dialog_parts.dart'
s = io.open(src, encoding='utf-8').read()

header = """import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hentai_library/design-system/design_system.dart';

"""


def cut(text, start_marker):
    i = text.index(start_marker)
    return text[:i], text[i:]


s, accordion = cut(s, 'class MetadataImportDetailsAccordion')
s = s.rstrip() + '\n'
# figure order in remaining: section heading, summary line, preview sample line, path fn
rest = accordion
i_acc_end = rest.index('class MetadataImportSectionHeading')
accordion, rest = rest[:i_acc_end].rstrip() + '\n', rest[i_acc_end:]
i_sh_end = rest.index('class MetadataImportSummaryLine')
heading, rest = rest[:i_sh_end].rstrip() + '\n', rest[i_sh_end:]
i_sl_end = rest.index('class MetadataImportPreviewSampleLine')
summary, rest = rest[:i_sl_end].rstrip() + '\n', rest[i_sl_end:]
i_fn = rest.index('/// 长路径中间省略')
preview, path_fn = rest[:i_fn].rstrip() + '\n', rest[i_fn:].rstrip() + '\n'

files = {
    'metadata_import_details_accordion.dart': accordion,
    'metadata_import_section_heading.dart': heading,
    'metadata_import_summary_line.dart': summary,
    'metadata_import_preview_sample_line.dart': preview,
    'ellipsis_middle_path.dart': path_fn,
}
for name, body in files.items():
    io.open(base + name, 'w', encoding='utf-8', newline='\n').write(header + body)

barrel = header + '\n'.join(
    "export 'package:hentai_library/features/metadata_backup/presentation/widgets/%s';" % n
    for n in files
) + '\n'
io.open(src, 'w', encoding='utf-8', newline='\n').write(barrel)
print('ok')
