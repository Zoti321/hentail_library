import io
import subprocess

base = 'lib/features/reading_history/presentation/patterns/history/'
orig = subprocess.check_output(
    ['git', 'show', 'HEAD:app/' + base + 'reading_history_list_layout.dart']
).decode('utf-8')

const_marker = "/// 默认与 [RenderViewport.defaultCacheExtent] 对齐的预构建边距。\nconst double _kHistoryGridCacheExtent = 250;\n"
grid_marker = '/// 阅读历史卡片网格（盒模型）：按宽度决定 1–3 列，**固定行高虚拟化**。'
sliver_marker = '/// 阅读历史列表（sliver）：按视口宽度决定 1–3 列，按行懒构建。'
fn_marker = '@visibleForTesting\ndouble readingHistoryGridTotalHeight'
rows_marker = 'class _VirtualizedReadingHistoryListRows'

def slice_between(text, a, b):
    i = text.index(a)
    j = text.index(b) if b else len(text)
    return text[i:j].rstrip() + '\n'

grid = slice_between(orig, grid_marker, sliver_marker)
sliver = slice_between(orig, sliver_marker, fn_marker)
helper = slice_between(orig, fn_marker, rows_marker)
rows = orig[orig.index(rows_marker):].rstrip() + '\n'

rows = rows.replace('_VirtualizedReadingHistoryListRows', 'ReadingHistoryVirtualizedRows')
rows = rows.replace('_ReadingHistoryListRow', 'ReadingHistoryListRow')
sliver = sliver.replace('_ReadingHistoryListRow', 'ReadingHistoryListRow')
grid = grid.replace('_VirtualizedReadingHistoryListRows', 'ReadingHistoryVirtualizedRows')

rows_file = """import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

""" + const_marker + helper + '\n' + rows
io.open(base + 'reading_history_virtualized_rows.dart', 'w', encoding='utf-8', newline='\n').write(rows_file)

sliver_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

""" + sliver
io.open(base + 'reading_history_list_sliver.dart', 'w', encoding='utf-8', newline='\n').write(sliver_file)

layout_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

""" + grid + """
export 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_list_sliver.dart';
export 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
"""
io.open(base + 'reading_history_list_layout.dart', 'w', encoding='utf-8', newline='\n').write(layout_file)
print('ok')
