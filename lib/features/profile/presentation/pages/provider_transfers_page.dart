import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderTransfersPage extends StatelessWidget {
  const ProviderTransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Histórico de Repasses',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo do Mês
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recebido em Setembro',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ 1.850,00',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'PRÓXIMOS REPASSES',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTransferItem(
              title: 'Repasse Semanal Jobble',
              date: 'Previsto: 20 Set 2026',
              amount: 'R\$ 450,00',
              status: 'Em processamento',
              statusColor: Colors.orange,
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'REPASSES CONCLUÍDOS',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTransferItem(
              title: 'Repasse Semanal Jobble',
              date: '13 Set 2026',
              amount: 'R\$ 850,00',
              status: 'Concluído',
              statusColor: colors.primary,
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTransferItem(
              title: 'Repasse Semanal Jobble',
              date: '06 Set 2026',
              amount: 'R\$ 550,00',
              status: 'Concluído',
              statusColor: colors.primary,
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTransferItem(
              title: 'Repasse Especial (Bônus)',
              date: '31 Ago 2026',
              amount: 'R\$ 100,00',
              status: 'Concluído',
              statusColor: colors.primary,
              colors: colors,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferItem({
    required String title,
    required String date,
    required String amount,
    required String status,
    required Color statusColor,
    required AppColorsTheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusColor == Colors.orange
                  ? LucideIcons.clock
                  : LucideIcons.circle_check,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
