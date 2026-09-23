import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/requests/domain/job_progress.dart';

/// Onde o profissional marca o que já entregou.
///
/// A régua de passos no topo é um resumo: boa para olhar, péssima para tocar —
/// o alvo era um círculo de 28px sem nada dizendo que era botão, e some da
/// tela ao primeiro rolar. Concluir etapa é a ação principal desta tela, então
/// ganha uma lista de verdade: linha inteira clicável, nome legível e um botão
/// escrito na etapa da vez.
class JobStepsChecklist extends StatelessWidget {
  const JobStepsChecklist({
    super.key,
    required this.steps,
    required this.onToggle,
  });

  final List<JobTask> steps;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    // A etapa da vez é a primeira pendente: é nela que o botão aparece.
    final current = steps.indexWhere((step) => !step.done);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == steps.length - 1 ? 0 : AppSpacing.xs,
            ),
            child: _StepRow(
              key: ValueKey('job-step-row-$i'),
              index: i,
              step: steps[i],
              isCurrent: i == current,
              onTap: () => onToggle(i),
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.index,
    required this.step,
    required this.isCurrent,
    required this.onTap,
  });

  final int index;
  final JobTask step;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final done = step.done;

    return Semantics(
      button: true,
      checked: done,
      label: done
          ? '${step.title}, concluída. Toque para reabrir.'
          : '${step.title}, pendente. Toque para concluir.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: isCurrent
                  ? colors.primary.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent ? colors.primary : colors.borderLight,
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _Marker(done: done, index: index, colors: colors),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: AppTypography.body.copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: done
                              ? colors.textSecondary
                              : colors.textPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: colors.textSecondary,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Etapa atual',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _Action(done: done, isCurrent: isCurrent, colors: colors),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O visto à esquerda: verde quando concluída, número quando ainda falta.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.done,
    required this.index,
    required this.colors,
  });

  final bool done;
  final int index;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done ? colors.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? colors.primary : colors.borderLight,
          width: 2,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : Text(
                '${index + 1}',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
      ),
    );
  }
}

/// A palavra que falta para ninguém precisar adivinhar: a etapa da vez diz
/// "Concluir", a já feita oferece desfazer, e as futuras ficam quietas.
class _Action extends StatelessWidget {
  const _Action({
    required this.done,
    required this.isCurrent,
    required this.colors,
  });

  final bool done;
  final bool isCurrent;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Icon(
        LucideIcons.rotate_ccw,
        size: 16,
        color: colors.textSecondary,
      );
    }

    if (!isCurrent) {
      return Text(
        'Toque para concluir',
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          color: colors.textSecondary,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Concluir',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
