import 'package:flutter/material.dart';
import 'package:material_expressive/theme.dart';

/// Fake catalog grid for MD3E Lab / Widgetbook (no domain types).
class Md3eLibraryBrowsePreviewView extends StatelessWidget {
  const Md3eLibraryBrowsePreviewView({super.key, this.itemCount = 12});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ExpressiveThemeData tokens = ExpressiveThemeProvider.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.all(tokens.spacing.lg),
          sliver: SliverToBoxAdapter(
            child: Text(
              '书库预览',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: tokens.spacing.md,
              crossAxisSpacing: tokens.spacing.md,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Material(
                  color: scheme.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radius.lg),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(tokens.spacing.sm),
                        child: Text(
                          '示例本子 ${index + 1}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}
