import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/button/home_refresh_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref
        .watch(rawDataComicsProvider)
        .maybeWhen(data: (data) => data.length, orElse: () => 0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: .all(24),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 32),
            _buildHeroWidgets(context, c.toString()),
            const SizedBox(height: 40),
            _buildContinueReadingSection(context),
            const SizedBox(height: 40),
            _buildLibraryGridSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      crossAxisAlignment: .end,
      children: [
        Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              '首页',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: .bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '下午好，读者',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            HomeRefreshButton(
              onPressed: () async {
                ref.invalidate(rawDataComicsProvider);
              },
            ),
            FilledButton.icon(
              onPressed: () async {
                try {
                  await ref.read(syncComicsUseCaseProvider).call();
                } on AppException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('扫描漫画库'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroWidgets(BuildContext context, String count) {
    return Row(
      children: [
        Container(
          padding: .all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            crossAxisAlignment: .start,
            children: [
              Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    '漫画库',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      children: [
                        TextSpan(
                          text: '+3 new ',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '本周'),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.bookImage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(
              '继续阅读',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                children: [
                  Text(
                    '查看全部',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLibraryGridSection() {
    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          '最近添加',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: 2,
          itemBuilder: (BuildContext context, int index) {
            return Column(crossAxisAlignment: .start, children: []);
          },
        ),
      ],
    );
  }
}

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: .all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: .circular(6),
            child: Container(width: 60, height: 80, color: Colors.grey[300]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisAlignment: .center,
              children: [
                const Text(
                  'Sakura Blooming Days',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chapter 5',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: .circular(4),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 6,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
