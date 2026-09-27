import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderHelpCenterPage extends StatefulWidget {
  const ProviderHelpCenterPage({super.key});

  @override
  State<ProviderHelpCenterPage> createState() => _ProviderHelpCenterPageState();
}

class _ProviderHelpCenterPageState extends State<ProviderHelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final List<Map<String, dynamic>> _faqItems = [
    {
      'category': 'Orçamentos',
      'question': 'Como faço para enviar orçamentos formais?',
      'answer':
          'Ao receber uma solicitação de cliente, acesse o chat da solicitação, avalie as necessidades e clique em "Criar Orçamento". Detalhe o escopo, materiais, prazo e valor, e aguarde a aprovação digital do cliente.',
    },
    {
      'category': 'Cancelamento',
      'question': 'O que acontece se o cliente cancelar?',
      'answer':
          'Se o cliente cancelar com menos de 24 horas de antecedência ou não estiver no local no momento agendado, você poderá receber uma taxa de deslocamento/cancelamento, conforme nossos Termos de Garantia e Políticas.',
    },
    {
      'category': 'Perfil',
      'question': 'Como melhorar minha visibilidade no aplicativo?',
      'answer':
          'Mantenha seu perfil completo com fotos de serviços anteriores, solicite avaliações dos clientes após a conclusão, e responda rapidamente às solicitações de orçamento para melhorar sua pontuação de engajamento.',
    },
    {
      'category': 'Garantia',
      'question': 'O que é a Garantia Jobble Protege?',
      'answer':
          'A Garantia Jobble cobre serviços intermediados na plataforma por até 90 dias. Caso o cliente acione a garantia, você terá a oportunidade de corrigir o defeito reportado sem penalidades adicionais antes da mediação final.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final filteredFaqs = _faqItems.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item['question']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat =
          _selectedCategory == null || item['category'] == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Central de Ajuda (Prestador)',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Banner de Boas-Vindas e Busca
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF047857), colors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Como podemos ajudar seu negócio hoje?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pesquise sua dúvida ou escolha uma categoria abaixo:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Pesquise por taxas, orçamentos, prazos...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        color: Colors.grey,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Categorias Rápidas
          Text(
            'CATEGORIAS',
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Row(
            children: [
              _buildCategoryChip('Todos', null, LucideIcons.layers),
              const SizedBox(width: 8),
              _buildCategoryChip(
                'Orçamentos',
                'Orçamentos',
                LucideIcons.file_text,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // FAQ Accordion
          Text(
            'DÚVIDAS FREQUENTES (FAQ)',
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          if (filteredFaqs.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderLight),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.circle_question_mark,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum artigo encontrado',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tente pesquisar com outros termos ou entre em contato com o suporte.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < filteredFaqs.length; i++) ...[
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.circle_question_mark,
                            color: colors.primary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          filteredFaqs[i]['question']!,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 56,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Text(
                              filteredFaqs[i]['answer']!,
                              style: AppTypography.body.copyWith(
                                color: colors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < filteredFaqs.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // Canais de Atendimento
          Text(
            'FALE COM A EQUIPE JOBBLE',
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.message_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'WhatsApp de Suporte',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    '(11) 98765-4321 • Resposta em até 5 min',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Iniciar',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Abrindo canal oficial de suporte no WhatsApp: (11) 98765-4321',
                        ),
                        backgroundColor: Color(0xFF25D366),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.mail,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'E-mail Oficial',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'suporte@jobble.com.br • Retorno em até 24h',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Enviar',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'E-mail de suporte: suporte@jobble.com.br copiado!',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Horário de Atendimento
          Center(
            child: Text(
              'Horário de atendimento: Segunda a Sexta das 08h às 20h | Sábado das 09h às 15h',
              style: AppTypography.caption.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    String? categoryValue,
    IconData icon,
  ) {
    final isSelected = _selectedCategory == categoryValue;
    final primary = Theme.of(context).primaryColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = isSelected ? null : categoryValue;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? primary : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
