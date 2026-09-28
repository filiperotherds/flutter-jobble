import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_card.dart';
import 'package:flutter_tcc/core/widgets/app_status_chip.dart';
import 'package:flutter_tcc/features/bids/presentation/widgets/job_stage_chip.dart';
import 'package:flutter_tcc/features/bids/data/models/org_match_model.dart';

/// Um trabalho do painel, com os dados que `GET /matches` devolve.
///
/// Superfície neutra e CTA da marca. O rótulo comunica a etapa e o aviso
/// de urgência fica restrito ao badge, sem colorir todo o card.
class ProviderJobCard extends StatelessWidget {
  const ProviderJobCard({
    super.key,
    required this.match,
    required this.onOpen,
    this.onDecline,
  });

  final OrgMatch match;
  final VoidCallback onOpen;

  /// Só o chamado que ainda aguarda resposta pode ser recusado.
  final VoidCallback? onDecline;

  String get _actionLabel => switch (match.stage) {
    JobStage.awaitingResponse => 'Analisar',
    JobStage.contractToFill => 'Preencher contrato',
    JobStage.awaitingSignatures => 'Ver assinaturas',
    _ => 'Abrir',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final money = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final value = match.value;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    JobStageChip(stage: match.stage),
                    if (match.isEmergency)
                      AppStatusChip(label: 'Urgente', color: colors.warning),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _elapsed(match.createdAt),
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            match.displayTitle,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            // Antes da escolha do cliente só há bairro e cidade: o nome e o
            // endereço completo só aparecem depois da contratação.
            [
              if (match.clientName != null) 'Cliente: ${match.clientName}',
              match.addressLine ?? match.location,
              if (match.distanceKm > 0)
                '${match.distanceKm.toStringAsFixed(1)} km',
            ].whereType<String>().join(' • '),
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          if (value != null) ...[
            const SizedBox(height: 8),
            Text(
              money.format(value),
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (onDecline != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.textPrimary,
                      side: BorderSide(color: context.colors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Recusar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: onOpen,
                  child: Text(_actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _elapsed(DateTime moment) {
  final diff = DateTime.now().difference(moment);
  if (diff.inMinutes < 1) return 'Agora';
  if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Há ${diff.inHours} h';
  return 'Há ${diff.inDays} d';
}
