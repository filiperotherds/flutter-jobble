import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderTipsPage extends StatelessWidget {
  const ProviderTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Dicas de Ouro',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevron_left, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppColorsTheme.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Transform.scale(
                    scale: 1.45,
                    child: SizedBox(
                      height: 190,
                      child: Image.asset(
                        'assets/images/joberto_tips_header.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Seja um Prestador 5 Estrelas',
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF14300A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Siga nossas dicas para aumentar sua credibilidade, fechar mais serviços e ser o mais recomendado da sua região.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: const Color(0xFF1B4310),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Como ter sucesso na Jobble',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            
            _buildTipCard(
              context,
              icon: LucideIcons.zap,
              iconColor: Colors.amber.shade600,
              title: 'Responda rápido',
              description: 'Clientes valorizam agilidade. Prestadores que respondem orçamentos nos primeiros 15 minutos fecham 80% mais serviços.',
            ),
            
            _buildTipCard(
              context,
              icon: LucideIcons.star,
              iconColor: Colors.orange.shade500,
              title: 'Mantenha sua avaliação alta',
              description: 'Um serviço bem feito garante 5 estrelas. Clientes tendem a contratar apenas profissionais com média acima de 4.5.',
            ),
            
            _buildTipCard(
              context,
              icon: LucideIcons.clock,
              iconColor: Colors.blue.shade500,
              title: 'Pontualidade é essencial',
              description: 'Chegar no horário combinado demonstra profissionalismo e respeito. Em caso de imprevistos, avise o cliente pelo chat com antecedência.',
            ),
            
            _buildTipCard(
              context,
              icon: LucideIcons.camera,
              iconColor: Colors.purple.shade500,
              title: 'Capriche no portfólio',
              description: 'Adicione fotos claras e bem iluminadas dos serviços que você já realizou. Clientes compram com os olhos antes de fechar negócio.',
            ),
            
            _buildTipCard(
              context,
              icon: LucideIcons.message_circle,
              iconColor: Colors.green.shade600,
              title: 'Comunicação clara e cordial',
              description: 'Seja educado no chat, explique os detalhes do serviço de forma transparente e tire todas as dúvidas do cliente.',
            ),
            
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Entendi',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String description}) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
