import 'package:flutter/material.dart';
import 'package:flutter_tcc/features/legal/presentation/pages/verification_center_page.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/core/widgets/app_text_field.dart';

/// Dados profissionais em etapas, conforme o aplicativo de referência.
class ProviderSignupWizardPage extends StatefulWidget {
  const ProviderSignupWizardPage({super.key});

  @override
  State<ProviderSignupWizardPage> createState() =>
      _ProviderSignupWizardPageState();
}

class _ProviderSignupWizardPageState extends State<ProviderSignupWizardPage> {
  int _currentStep =
      0; // 0: Negócio, 1: Atendimento, 2: Contato & Pix, 3: Conclusão

  // Step 1: Dados do Negócio
  final _businessNameController = TextEditingController(
    text: 'Gabriel Pinturas e Reformas',
  );
  String _personType = 'MEI'; // 'Autônomo', 'MEI', 'Empresa (PJ)'
  final _docController = TextEditingController(text: '48.912.345/0001-90');
  String _selectedCategory = 'Pintura';

  // Step 2: Atendimento & Região
  final _cityController = TextEditingController(text: 'São Paulo, SP');
  String _selectedRadius = '20 km';
  final _descriptionController = TextEditingController(
    text:
        'Pintura residencial, acabamento fino, massas e texturas com alta qualidade e agilidade.',
  );

  // Step 3: Contato & Pix
  final _whatsappController = TextEditingController(text: '(11) 98765-4321');
  final _pixKeyController = TextEditingController(
    text: 'gabriel.silva@email.com',
  );
  bool _acceptedTerms = true;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _businessNameController.dispose();
    _docController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    _pixKeyController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1Key.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_step2Key.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_step3Key.currentState!.validate()) return;
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, aceite os Termos de Parceria para prosseguir.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.textPrimary),
          onPressed: () {
            if (_currentStep > 0 && _currentStep < 3) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Voltar',
        ),
        title: Text(
          _currentStep == 3 ? 'Cadastro Concluído' : 'Cadastro de Prestador',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de Progresso (se não for a tela de sucesso final)
            if (_currentStep < 3) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'Negócio', colors),
                    _buildStepDivider(0, colors),
                    _buildStepIndicator(1, 'Serviços', colors),
                    _buildStepDivider(1, colors),
                    _buildStepIndicator(2, 'Recebimento', colors),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: switch (_currentStep) {
                  0 => _buildStep1(colors),
                  1 => _buildStep2(colors),
                  2 => _buildStep3(colors),
                  3 => _buildSuccessStep(colors),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),

            // Barra inferior de navegação dos passos
            if (_currentStep < 3)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: colors.borderLight)),
                ),
                child: AppAccentButton(
                  label: _currentStep == 2 ? 'Finalizar Cadastro' : 'Continuar',
                  onPressed: _nextStep,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(
    int stepIndex,
    String title,
    AppColorsTheme colors,
  ) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? colors.primary
                : isActive
                ? colors.primary.withValues(alpha: 0.15)
                : colors.surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isDone ? colors.primary : colors.borderLight,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isActive ? colors.primary : colors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            fontWeight: isActive || isDone
                ? FontWeight.bold
                : FontWeight.normal,
            color: isActive || isDone
                ? colors.textPrimary
                : colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int stepIndex, AppColorsTheme colors) {
    final isDone = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isDone ? colors.primary : colors.borderLight,
      ),
    );
  }

  // Passo 1: Informações do Negócio
  Widget _buildStep1(AppColorsTheme colors) {
    final categories = [
      'Pintura',
      'Eletricista',
      'Limpeza',
      'Encanador',
      'Reformas',
      'Montagem',
    ];

    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Informações Profissionais',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Como você ou sua empresa serão apresentados aos clientes na plataforma.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppTextField(
            controller: _businessNameController,
            label: 'Nome da Empresa ou Nome Fantasia',
            hint: 'Ex: Silva Pinturas Residenciais',
            prefixIcon: LucideIcons.briefcase,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o nome profissional'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Tipo de Atuação',
            style: AppTypography.label.copyWith(color: colors.textBody),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['Autônomo', 'MEI', 'Empresa (PJ)'].map((type) {
              final selected = _personType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  selectedColor: colors.primary.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: selected ? colors.primary : colors.borderLight,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? colors.primary : colors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _personType = type);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            controller: _docController,
            label: _personType == 'Empresa (PJ)' || _personType == 'MEI'
                ? 'CNPJ'
                : 'CPF',
            prefixIcon: LucideIcons.file_text,
            keyboardType: TextInputType.number,
            inputFormatters: [_personType == 'Autônomo' ? _cpfMask : _cnpjMask],
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Documento obrigatório'
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Categoria Principal de Atuação',
            style: AppTypography.label.copyWith(color: colors.textBody),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final selected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceLight,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : colors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? colors.primary : colors.borderLight,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Passo 2: Região de Atuação & Serviços
  Widget _buildStep2(AppColorsTheme colors) {
    final radii = ['10 km', '20 km', '35 km', '50 km', 'Toda a Cidade'];

    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Região e Serviços',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Defina onde você atende e conte um pouco sobre sua experiência.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppTextField(
            controller: _cityController,
            label: 'Cidade e Estado Base',
            prefixIcon: LucideIcons.map_pin,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe sua cidade' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Raio Máximo de Deslocamento',
            style: AppTypography.label.copyWith(color: colors.textBody),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: radii.map((r) {
              final selected = _selectedRadius == r;
              return ChoiceChip(
                label: Text(r),
                selected: selected,
                selectedColor: colors.primary.withValues(alpha: 0.15),
                side: BorderSide(
                  color: selected ? colors.primary : colors.borderLight,
                ),
                labelStyle: TextStyle(
                  color: selected ? colors.primary : colors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedRadius = r);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Descrição dos seus Serviços e Diferenciais',
            style: AppTypography.label.copyWith(color: colors.textBody),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: AppTypography.body.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Fale sobre seus diferenciais, garantia oferecida, ferramentas e experiência...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Descreva seus serviços'
                : null,
          ),
        ],
      ),
    );
  }

  // Passo 3: Contato & Pix
  Widget _buildStep3(AppColorsTheme colors) {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3. Contato e Recebimento',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Para onde serão enviados os alertas de chamados e os pagamentos.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppTextField(
            controller: _whatsappController,
            label: 'WhatsApp Profissional',
            prefixIcon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [_phoneMask],
            validator: (v) => (v == null || v.trim().length < 14)
                ? 'Informe seu WhatsApp'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            controller: _pixKeyController,
            label: 'Chave Pix para Recebimentos',
            hint: 'CPF, CNPJ, E-mail ou Telefone',
            prefixIcon: LucideIcons.zap,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe sua chave Pix'
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  activeColor: colors.primary,
                  onChanged: (val) =>
                      setState(() => _acceptedTerms = val ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Li e concordo com os Termos de Parceria Jobble, compromisso de pontualidade e integridade no atendimento aos clientes.',
                      style: AppTypography.caption.copyWith(
                        color: colors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Passo 4: Tela de Sucesso Explicativa
  Widget _buildSuccessStep(AppColorsTheme colors) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.circle_check,
            color: Color(0xFF10B981),
            size: 72,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Dados profissionais preenchidos!',
          style: AppTypography.h1.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Confira os dados e a verificação da sua conta para concluir seu cadastro profissional.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Card informativo sobre o aplicativo exclusivo do prestador
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.smartphone,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Aplicativo Jobble Prestador',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'O lado do prestador funciona em um aplicativo separado. Lá você tem acesso exclusivo para:',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildBulletItem(
                'Receber e aceitar solicitações de clientes da sua região',
              ),
              _buildBulletItem(
                'Gerar e enviar orçamentos formais com assinatura digital',
              ),
              _buildBulletItem('Gerenciar sua agenda de serviços e calendário'),
              _buildBulletItem(
                'Acompanhar transferências bancárias e ganhos das diárias',
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.key, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você está no Jobble Prestador. Seu cadastro e documentos ficam na central de verificação.',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // A conta e sua verificação pertencem a este aplicativo.
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const VerificationCenterPage(),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(LucideIcons.download, color: Colors.white, size: 20),
          label: const Text(
            'Conferir cadastro da conta',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Voltar ao Meu Perfil',
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 8),
            child: Icon(
              LucideIcons.circle_check,
              size: 14,
              color: Color(0xFF10B981),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
