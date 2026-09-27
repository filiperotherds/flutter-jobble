import 'package:flutter/material.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/requests/domain/job_progress.dart';

/// As etapas do serviço como passos, no lugar de uma barra.
///
/// Uma barra diz "50%" e para por aí. Aqui cada etapa é um passo que fica
/// verde ao ser concluído, com o nome embaixo: dá para ver o que já foi
/// entregue e o que vem a seguir, não só quanto falta.
///
/// Três estados, não dois: concluída, **em andamento** e pendente. Saber qual
/// é a etapa da vez é metade da pergunta que se faz olhando para o serviço.
class ServiceStepper extends StatelessWidget {
  const ServiceStepper({
    super.key,
    required this.steps,
    this.onToggle,
    this.showLabels = true,
  });

  final List<JobTask> steps;

  /// Marca ou desmarca a etapa. Sem isto, o passo a passo é só leitura — que
  /// é como o cliente o vê.
  final ValueChanged<int>? onToggle;

  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (steps.isEmpty) return const SizedBox.shrink();

    // A etapa da vez é a primeira que ainda não foi concluída. Se não houver
    // nenhuma, o serviço acabou e ninguém está "em andamento".
    final current = steps.indexWhere((step) => !step.done);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // O trilho até o passo anterior: verde quando os dois já
                    // foram concluídos.
                    Expanded(
                      child: _Track(
                        visible: i > 0,
                        done: i > 0 && steps[i - 1].done && steps[i].done,
                        colors: colors,
                      ),
                    ),
                    _Dot(
                      // Chave estável: é por ela que o teste toca num passo.
                      key: ValueKey('service-step-$i'),
                      index: i,
                      done: steps[i].done,
                      isCurrent: i == current,
                      compact: !showLabels,
                      onTap: onToggle == null ? null : () => onToggle!(i),
                      colors: colors,
                    ),
                    Expanded(
                      child: _Track(
                        visible: i < steps.length - 1,
                        done:
                            i < steps.length - 1 &&
                            steps[i].done &&
                            steps[i + 1].done,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                if (showLabels) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      steps[i].title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        height: 1.25,
                        fontWeight: steps[i].done || i == current
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: i == current
                            ? const Color(0xFF1C574A)
                            : steps[i].done
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// O segmento de linha entre dois passos.
class _Track extends StatelessWidget {
  const _Track({
    required this.visible,
    required this.done,
    required this.colors,
  });

  final bool visible;
  final bool done;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 3,
      color: !visible
          ? Colors.transparent
          : done
          ? const Color(0xFF1C574A)
          : colors.borderLight,
    );
  }
}

/// O passo em si: verde com um visto quando concluído, contornado quando é a
/// etapa da vez, apagado quando ainda vai chegar.
class _Dot extends StatelessWidget {
  const _Dot({
    super.key,
    required this.index,
    required this.done,
    required this.isCurrent,
    required this.compact,
    required this.onTap,
    required this.colors,
  });

  final int index;
  final bool done;
  final bool isCurrent;

  /// Dentro de um card a régua toda tem meia dúzia de linhas: o passo encolhe
  /// para não roubar a cena do resto.
  final bool compact;

  final VoidCallback? onTap;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 22.0 : 28.0;
    final border = done || isCurrent ? const Color(0xFF1C574A) : colors.borderLight;

    return GestureDetector(
      onTap: onTap,
      // Passo pequeno numa tela de toque: a área sensível é maior que o
      // desenho, senão errar o alvo vira regra.
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: AppSpacing.xs,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF1C574A) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
            // Um halo discreto marca onde o serviço está agora.
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: const Color(0xFF1C574A).withValues(alpha: 0.18),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: done
                ? Icon(
                    Icons.check,
                    size: compact ? 13 : 16,
                    color: Colors.white,
                  )
                : Text(
                    '${index + 1}',
                    style: AppTypography.caption.copyWith(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? const Color(0xFF1C574A) : colors.textSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
