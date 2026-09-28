import 'package:flutter/material.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

/// Uma opção da [AppFilterChips]: rótulo e, quando faz sentido, quantos itens
/// o filtro devolve.
class AppFilterOption<T> {
  const AppFilterOption({required this.value, required this.label, this.count});

  final T value;
  final String label;

  /// Mostrado ao lado do rótulo, como no `Tabs` do sistema ("Income ($4.800)").
  /// Nulo esconde o número — filtro sem contagem não inventa zero.
  final int? count;
}

/// Faixa de filtros em pills, rolável na horizontal.
///
/// É a forma de "abas dentro do conteúdo" do sistema: a seleção soma três
/// sinais — fundo lima pálido, borda lima e peso do rótulo — para não depender
/// só de cor. O lima aqui é preenchimento; a tinta continua floresta.
class AppFilterChips<T> extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.options,
    required this.value,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  final List<AppFilterOption<T>> options;
  final T value;
  final ValueChanged<T> onSelected;

  /// Use a margem da tela quando a faixa rola de borda a borda, para o
  /// primeiro chip nascer alinhado ao conteúdo e o último não colar na beira.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            _Chip(
              option: options[i],
              selected: options[i].value == value,
              onTap: () => onSelected(options[i].value),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip<T> extends StatelessWidget {
  const _Chip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppFilterOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = option.count;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.accentSoft : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: AppSize.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSize.iconButton),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: AppSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  style: AppTypography.label.copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppSpacing.xxs + 2),
                  Text(
                    '$count',
                    style: AppTypography.label.copyWith(
                      fontSize: 13,
                      color: selected ? colors.accentText : colors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
