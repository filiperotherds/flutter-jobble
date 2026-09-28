import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';

/// Botão de voltar das telas empilhadas.
///
/// O tema desenha todo `IconButton` como um círculo de [AppSize.iconButton];
/// no espaço de leading padrão da app bar (56pt) ele fica centralizado e sobra
/// alguns pixels à esquerda da margem da tela. Aqui o círculo começa
/// exatamente em [AppSpacing.screenH], alinhado ao conteúdo abaixo — por isso
/// a app bar precisa reservar [slotWidth].
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  /// O que a app bar deve passar em `leadingWidth`.
  static const double slotWidth = AppSize.iconButton + AppSpacing.screenH;

  @override
  Widget build(BuildContext context) {
    // Espelha o `automaticallyImplyLeading` da app bar: sem rota para voltar e
    // sem ação própria, não há botão — só o espaço reservado.
    if (onPressed == null && !Navigator.of(context).canPop()) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.screenH),
      child: Center(
        child: AppCircleIconButton(
          icon: LucideIcons.arrow_left,
          tooltip: 'Voltar',
          onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
