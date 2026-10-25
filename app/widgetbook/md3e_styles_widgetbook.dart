import 'package:flutter/material.dart';
import 'package:material_expressive/theme.dart';
import 'package:material_expressive/tokens.dart';
import 'package:widgetbook/widgetbook.dart';

import 'md3e_widgetbook_scope.dart';

/// M3-style **styles** tree (color / shape / spacing / typography), not widgets.
List<WidgetbookNode> buildMd3eStylesWidgetbookNodes() {
  return <WidgetbookNode>[
    WidgetbookFolder(
      name: 'styles',
      children: <WidgetbookNode>[
        WidgetbookComponent(
          name: 'color',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Key roles',
              builder: (BuildContext context) => Md3eWidgetbookScope(
                child: Builder(
                  builder: (BuildContext context) {
                    final ExpressiveColorTokens colors =
                        ExpressiveThemeProvider.of(context).colors;
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _ColorChip(label: 'primary', color: colors.primary),
                          _ColorChip(
                            label: 'secondary',
                            color: colors.secondary,
                          ),
                          _ColorChip(
                            label: 'tertiary',
                            color: colors.tertiary,
                          ),
                          _ColorChip(label: 'surface', color: colors.surface),
                          _ColorChip(
                            label: 'surfaceContainerLow',
                            color: colors.surfaceContainerLow,
                          ),
                          _ColorChip(
                            label: 'error',
                            color: colors.error,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'shape',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Corner radius scale',
              builder: (BuildContext context) => Md3eWidgetbookScope(
                child: Builder(
                  builder: (BuildContext context) {
                    final ExpressiveThemeData tokens =
                        ExpressiveThemeProvider.of(context);
                    final ColorScheme scheme = Theme.of(context).colorScheme;
                    return Padding(
                      padding: EdgeInsets.all(tokens.spacing.lg),
                      child: Wrap(
                        spacing: tokens.spacing.md,
                        runSpacing: tokens.spacing.md,
                        children: <Widget>[
                          _RadiusTile(
                            label: 'xs ${tokens.radius.xs}',
                            radius: tokens.radius.xs,
                            color: scheme.primaryContainer,
                          ),
                          _RadiusTile(
                            label: 'md ${tokens.radius.md}',
                            radius: tokens.radius.md,
                            color: scheme.secondaryContainer,
                          ),
                          _RadiusTile(
                            label: 'lg ${tokens.radius.lg}',
                            radius: tokens.radius.lg,
                            color: scheme.tertiaryContainer,
                          ),
                          _RadiusTile(
                            label: 'xl ${tokens.radius.xl}',
                            radius: tokens.radius.xl,
                            color: scheme.surfaceContainerHigh,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'spacing',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Scale (phone preset)',
              builder: (BuildContext context) => const Md3eWidgetbookScope(
                child: _SpacingScalePreview(),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'typography',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Type scale',
              builder: (BuildContext context) => const Md3eWidgetbookScope(
                child: _TypographyScalePreview(),
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _RadiusTile extends StatelessWidget {
  const _RadiusTile({
    required this.label,
    required this.radius,
    required this.color,
  });

  final String label;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _SpacingScalePreview extends StatelessWidget {
  const _SpacingScalePreview();

  @override
  Widget build(BuildContext context) {
    final ExpressiveSpacingTokens spacing =
        ExpressiveThemeProvider.of(context).spacing;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        _SpacingBar(label: 'xxs', value: spacing.xxs),
        _SpacingBar(label: 'xs', value: spacing.xs),
        _SpacingBar(label: 'sm', value: spacing.sm),
        _SpacingBar(label: 'md', value: spacing.md),
        _SpacingBar(label: 'lg', value: spacing.lg),
        _SpacingBar(label: 'xl', value: spacing.xl),
      ],
    );
  }
}

class _SpacingBar extends StatelessWidget {
  const _SpacingBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Container(
            width: value * 4,
            height: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text('$value dp'),
        ],
      ),
    );
  }
}

class _TypographyScalePreview extends StatelessWidget {
  const _TypographyScalePreview();

  @override
  Widget build(BuildContext context) {
    final ExpressiveTypographyTokens type =
        ExpressiveThemeProvider.of(context).typography;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Display large', style: type.displayLarge),
        Text('Headline small', style: type.headlineSmall),
        Text('Title medium', style: type.titleMedium),
        Text('Body large', style: type.bodyLarge),
        Text('Label large', style: type.labelLarge),
      ],
    );
  }
}
