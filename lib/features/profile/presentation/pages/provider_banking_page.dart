import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderBankingPage extends StatelessWidget {
  const ProviderBankingPage({super.key});

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
          'Dados Bancários',
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
            // Saldo e Saque
            _buildBalanceCard(colors),
            const SizedBox(height: AppSpacing.xl),

            // Chave PIX
            Text(
              'Chave PIX Principal',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildPixCard(colors),
            const SizedBox(height: AppSpacing.xl),

            // Contas Bancárias
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contas Bancárias',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Adicionar'),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBankAccountCard(
              'Nubank',
              'Ag: 0001  CC: 1234567-8',
              'assets/images/nubank_logo.png',
              colors,
            ), // Mock logo string, will use icon for now
            const SizedBox(height: AppSpacing.sm),
            _buildBankAccountCard(
              'Itaú Unibanco',
              'Ag: 4321  CC: 98765-4',
              'assets/images/itau_logo.png',
              colors,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Disponível',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              Icon(LucideIcons.info, size: 16, color: colors.borderLight),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ 1.500,00',
            style: AppTypography.h1.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Solicitar Saque',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixCard(AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
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
              color: colors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.zap,
              color: colors.primary,
            ), // Simulando o ícone PIX
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Celular',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '(11) 98765-4321',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Editar')),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(
    String bankName,
    String details,
    String logoString,
    AppColorsTheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.landmark, color: Colors.grey),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.ellipsis_vertical, size: 20),
            onPressed: () {},
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}
