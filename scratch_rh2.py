import io

base = 'lib/features/reading_history/presentation/patterns/history/'
p = base + 'reading_history_list_layout.dart'
s = io.open(p, encoding='utf-8').read()

# 1. capture constant
const_marker = "/// 默认与 [RenderViewport.defaultCacheExtent] 对齐的预构建边距。\nconst double _kHistoryGridCacheExtent = 250;\n"
const_block = const_marker
s = s.replace(const_block, '')

# 2. capture grid class
grid_start = s.index('/// 阅读历史卡片网格（盒模型）：按宽度决定 1–3 列，**固定行高虚拟化**。')
grid_end = s.index('/// 阅读历史列表（sliver）：按视口宽度决定 1–3 列，按行懒构建。')
grid = s[grid_start:grid_end].rstrip() + '\n'
s = s[:grid_start] + s[grid_end:]

# 3. capture sliver class
sliver_end = s.index('@visibleForTesting\ndouble readingHistoryGridTotalHeight')
sliver = s[s.index('/// 阅读历史列表（sliver）'):sliver_end].rstrip() + '\n'
s = s[: s.index('/// 阅读历史列表（sliver）')] + s[sliver_end:]

# 4. capture helper fn (until _Virtualized class)
fn_start = s.index('@visibleForTesting')
fn_end = s.index('class _VirtualizedReadingHistoryListRows')
helper = s[fn_start:fn_end].rstrip() + '\n'
s = s[:fn_start] + s[fn_end:]

# 5. rest = virtualized rows + row widget
rows = s[fn_end:].rstrip() + '\n'

# rename private virtualized widget to public
rows = rows.replace('_VirtualizedReadingHistoryListRows', 'ReadingHistoryVirtualizedRows')

rows_file = """import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

""" + const_block + helper + '\n' + rows
io.open(base + 'reading_history_virtualized_rows.dart', 'w', encoding='utf-8', newline='\n').write(rows_file)

sliver_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

""" + sliver
io.open(base + 'reading_history_list_sliver.dart', 'w', encoding='utf-8', newline='\n').write(sliver_file)

grid = grid.replace('_VirtualizedReadingHistoryListRows', 'ReadingHistoryVirtualizedRows')
layout_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

""" + grid + """
export 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_list_sliver.dart';
export 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
"""
io.open(p, 'w', encoding='utf-8', newline='\n').write(layout_file)
print('ok')
