import io

base = 'lib/features/reading_history/presentation/patterns/history/'
p = base + 'reading_history_list_layout.dart'
s = io.open(p, encoding='utf-8').read()

i = s.index('/// 阅读历史列表（sliver）：按视口宽度决定 1–3 列，按行懒构建。')
# find end of ReadingHistoryListLayout class: next top-level declaration after it
j = s.index('@visibleForTesting\ndouble readingHistoryGridTotalHeight')
sliver = s[i:j].rstrip() + '\n'
rest = s[:i] + s[j:]

sliver_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_list_layout.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

""" + sliver
io.open(base + 'reading_history_list_sliver.dart', 'w', encoding='utf-8', newline='\n').write(sliver_file)

rest = rest.rstrip() + "\n\nexport 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_list_sliver.dart';\n"
io.open(p, 'w', encoding='utf-8', newline='\n').write(rest)
print('ok')
