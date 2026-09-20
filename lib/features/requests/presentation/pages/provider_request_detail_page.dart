import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_quote_generator_page.dart';

class ProviderRequestDetailPage extends StatefulWidget {
  const ProviderRequestDetailPage({super.key});

  @override
  State<ProviderRequestDetailPage> createState() =>
      _ProviderRequestDetailPageState();
}

class _ProviderRequestDetailPageState extends State<ProviderRequestDetailPage> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Analisar Pedido',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Alerta superior
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, color: Colors.orange),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'O cliente Gabriel está aguardando seu orçamento. Envie o mais rápido possível para fechar o negócio!',
                    style: AppTypography.caption.copyWith(
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Informações do Serviço
          Text(
            'Detalhes do Serviço',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            LucideIcons.map_pin,
            'Endereço',
            'Bairro Jardim Botânico (Aprox. 2km)',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(LucideIcons.calendar, 'Urgência', 'O quanto antes'),

          const SizedBox(height: AppSpacing.xl),

          // Descrição do cliente
          Text(
            'Descrição do Cliente',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"Olá Roberto! Preciso pintar a parede da minha sala. Tem mais ou menos uns 20m² e está começando a descascar por causa de umidade antiga. Já resolvi o vazamento, agora preciso só lixar e pintar de branco. Consegue dar uma olhada na foto e me mandar um orçamento?"',
              style: AppTypography.body.copyWith(
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Anexos
          Text(
            'Fotos Anexadas (1)',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/portfolio_painting.jpg', // Usando mock de portfolio_painting
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('parede_descascando.jpg'),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // Formulário de Orçamento
          Text(
            'Enviar Proposta',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Valor Estimado (Mão de obra)',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              hintText: '0,00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Mensagem para o cliente (Opcional)',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Ex: O valor já inclui o material para lixar a parede...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Recusar Pedido',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProviderQuoteGeneratorPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Enviar Proposta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.caption.copyWith(color: Colors.grey[600]),
            ),
            Text(
              value,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
