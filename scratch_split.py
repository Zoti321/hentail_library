import io, re, sys

base = 'lib/features/metadata_backup/presentation/widgets/'
res_path = base + 'metadata_import_result_dialog.dart'
s = io.open(res_path, encoding='utf-8').read()
i = s.index('class _MetadataImportDetailsAccordion')
main = s[:i].rstrip() + '\n'
parts = s[i:].rstrip() + '\n'

renames = {
    '_MetadataImportDetailsAccordion': 'MetadataImportDetailsAccordion',
    '_SectionHeading': 'MetadataImportSectionHeading',
    '_SummaryLine': 'MetadataImportSummaryLine',
    '_PreviewSampleLine': 'MetadataImportPreviewSampleLine',
}
for old, new in renames.items():
    parts = parts.replace(old, new)

parts_header = """import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

"""
io.open(base + 'metadata_import_dialog_parts.dart', 'w', encoding='utf-8', newline='\n').write(parts_header + parts)

main = main.replace(
    "import 'package:material_3_expressive/material_3_expressive.dart';",
    "import 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialog_parts.dart';\nimport 'package:material_3_expressive/material_3_expressive.dart';\n\nexport 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialog_parts.dart';",
    1,
)
io.open(res_path, 'w', encoding='utf-8', newline='\n').write(main)

conf = base + 'metadata_import_dialogs.dart'
c = io.open(conf, encoding='utf-8').read()
for old, new in renames.items():
    c = c.replace(old, new)
c = c.replace(
    "import 'package:material_3_expressive/material_3_expressive.dart';",
    "import 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialog_parts.dart';\nimport 'package:material_3_expressive/material_3_expressive.dart';",
    1,
)
io.open(conf, 'w', encoding='utf-8', newline='\n').write(c)
print('ok')
