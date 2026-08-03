import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';

class FluentNumberStepperField extends HookWidget {
  const FluentNumberStepperField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.labelText,
    this.labelTrailing,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
    this.step = 0.1,
    this.isDense = false,
  });

  static const Key incrementKey = Key('fluent_number_stepper_increment');
  static const Key decrementKey = Key('fluent_number_stepper_decrement');

  final String? initialValue;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final String? labelText;
  final Widget? labelTrailing;
  final String? errorText;
  final bool autofocus;
  final bool enabled;
  final double step;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextEditingController controller = useTextEditingController(
      text: initialValue ?? '',
    );
    final FocusNode textFocusNode = useFocusNode();
    final ValueNotifier<bool> isFocused = useState(false);
    // 点步进器时 TextField 会短暂失焦；按住期间保持 chrome/步进器可见，避免闪烁。
    final ValueNotifier<bool> stepperHeld = useState(false);
    final ObjectRef<bool> suppressSelectAll = useRef(false);

    useEffect(() {
      void onFocusChange() {
        isFocused.value = textFocusNode.hasFocus;
        if (textFocusNode.hasFocus && suppressSelectAll.value) {
          final String text = controller.text;
          controller.selection = TextSelection.collapsed(offset: text.length);
        }
      }

      void onControllerTick() {
        if (!suppressSelectAll.value || controller.selection.isCollapsed) {
          return;
        }
        final String text = controller.text;
        controller.selection = TextSelection.collapsed(offset: text.length);
      }

      textFocusNode.addListener(onFocusChange);
      controller.addListener(onControllerTick);
      isFocused.value = textFocusNode.hasFocus;
      return () {
        textFocusNode.removeListener(onFocusChange);
        controller.removeListener(onControllerTick);
      };
    }, <Object?>[textFocusNode, controller]);

    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final bool fieldActive = isFocused.value || stepperHeld.value;
    final bool showActiveBorder = enabled && fieldActive && !hasError;
    final Color borderColor = hasError
        ? cs.error
        : showActiveBorder
        ? cs.hentai.inputBorderActive
        : cs.hentai.inputBorder;
    final bool useDense = isDense;
    final bool showStepper = enabled && fieldActive;

    void collapseSelectionToEnd() {
      final String text = controller.text;
      final TextSelection caret = TextSelection.collapsed(offset: text.length);
      if (controller.selection != caret) {
        controller.selection = caret;
      }
    }

    /// 桌面端 requestFocus 常会全选文本（图一）；步进后强制回到末尾光标（图二）。
    void keepCaretAtEnd() {
      suppressSelectAll.value = true;
      collapseSelectionToEnd();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        collapseSelectionToEnd();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          collapseSelectionToEnd();
          suppressSelectAll.value = false;
        });
      });
    }

    void applyValue(double next) {
      final String text = _formatStepValue(next, step);
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      onChanged(text);
    }

    void stepBy(double delta) {
      final double current = _parseNumber(controller.text) ?? 0;
      applyValue(current + delta);
      textFocusNode.requestFocus();
      keepCaretAtEnd();
    }

    void onStepperPointerDown() {
      stepperHeld.value = true;
      textFocusNode.requestFocus();
      keepCaretAtEnd();
    }

    void onStepperPointerEnd() {
      stepperHeld.value = false;
      textFocusNode.requestFocus();
      keepCaretAtEnd();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (labelText != null) ...<Widget>[
          FormLabel(labelText!, trailing: labelTrailing),
          SizedBox(
            height: useDense ? tokens.spacing.xs : tokens.spacing.sm - 2,
          ),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            vertical: useDense ? 0 : tokens.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: cs.hentai.inputBackground,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: showActiveBorder
                ? <BoxShadow>[
                    BoxShadow(
                      color: cs.primary.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  focusNode: textFocusNode,
                  controller: controller,
                  autofocus: autofocus,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: tokens.text.bodyMd,
                    color: enabled
                        ? cs.hentai.textPrimary
                        : cs.hentai.textSecondary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: cs.hentai.textPlaceholder,
                      fontSize: tokens.text.bodyMd,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.md,
                      vertical: useDense
                          ? tokens.spacing.xs
                          : tokens.spacing.sm,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    filled: false,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: tokens.spacing.xs),
                child: ExcludeFocus(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) => onStepperPointerDown(),
                    onPointerUp: (_) => onStepperPointerEnd(),
                    onPointerCancel: (_) => onStepperPointerEnd(),
                    child: IgnorePointer(
                      ignoring: !showStepper,
                      child: Opacity(
                        opacity: showStepper ? 1 : 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _StepperButton(
                              key: incrementKey,
                              icon: Icons.keyboard_arrow_up,
                              onPressed: () => stepBy(step),
                            ),
                            _StepperButton(
                              key: decrementKey,
                              icon: Icons.keyboard_arrow_down,
                              onPressed: () => stepBy(-step),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...<Widget>[
          SizedBox(height: tokens.spacing.xs),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.error,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(tokens.radius.xs);
    return SizedBox(
      width: 28,
      height: 20,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Icon(icon, size: 16, color: cs.hentai.iconDefault),
        ),
      ),
    );
  }
}

double? _parseNumber(String text) {
  final double? value = double.tryParse(text.trim());
  if (value == null || !value.isFinite) {
    return null;
  }
  return value;
}

String _formatStepValue(double value, double step) {
  final int fractionDigits = _fractionDigitsForStep(step);
  if (fractionDigits == 0) {
    return value.round().toString();
  }
  final String formatted = value.toStringAsFixed(fractionDigits);
  if (!formatted.contains('.')) {
    return formatted;
  }
  return formatted
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

int _fractionDigitsForStep(double step) {
  final String text = step.toString();
  final int dotIndex = text.indexOf('.');
  if (dotIndex < 0) {
    return 0;
  }
  return text.length - dotIndex - 1;
}
