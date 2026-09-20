import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderPortfolioPage extends StatefulWidget {
  const ProviderPortfolioPage({super.key});

  @override
  State<ProviderPortfolioPage> createState() => _ProviderPortfolioPageState();
}

class _ProviderPortfolioPageState extends State<ProviderPortfolioPage> {
  // Mock data for portfolio items
  final List<Map<String, dynamic>> _portfolioItems = [
    {
      'images': [
        'assets/images/portfolio_painting.jpg',
        'assets/images/portfolio_cleaning.jpg',
      ],
      'title': 'Pintura de Fachada',
      'description':
          'Trabalho realizado em uma casa de 2 andares. Antes e depois!',
    },
    {
      'images': ['assets/images/portfolio_plumbing.jpg'],
      'title': 'Instalação de Pia',
      'description': 'Troca de tubulação e instalação de nova pia.',
    },
    {
      'images': ['assets/images/portfolio_electrical.jpg'],
      'title': 'Painel Elétrico',
      'description': 'Manutenção completa do painel principal.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Meu Portfólio',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _portfolioItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.image, size: 64, color: colors.borderLight),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Seu portfólio está vazio',
                    style: AppTypography.h3.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Adicione fotos e vídeos para atrair mais clientes.',
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _portfolioItems.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final item = _portfolioItems[index];
                return _PortfolioItemCard(
                  item: item,
                  colors: colors,
                  onDelete: () {
                    setState(() {
                      _portfolioItems.removeAt(index);
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProjectModal(context, colors),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Novo Projeto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddProjectModal(BuildContext context, AppColorsTheme colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adicionar Projeto',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Botão para adicionar fotos
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.borderLight,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.images,
                        size: 40,
                        color: colors.borderLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque para enviar VÁRIAS fotos ou vídeos',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.borderLight),
                        ),
                        child: Text(
                          'Fazer montagens, antes e depois, etc',
                          style: AppTypography.caption.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Título do Projeto',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Ex: Reforma do banheiro',
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
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Descrição ou Comentários',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Fale um pouco sobre o serviço realizado...',
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
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Projeto adicionado com sucesso!'),
                        ),
                      );
                      setState(() {
                        _portfolioItems.insert(0, {
                          'images': [
                            'assets/images/portfolio_cleaning.jpg',
                            'assets/images/portfolio_electrical.jpg',
                          ],
                          'title': 'Novo Projeto Adicionado',
                          'description':
                              'Descrição do novo projeto com múltiplas fotos.',
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Salvar Projeto',
                      style: AppTypography.h3.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PortfolioItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final AppColorsTheme colors;
  final VoidCallback onDelete;

  const _PortfolioItemCard({
    required this.item,
    required this.colors,
    required this.onDelete,
  });

  @override
  State<_PortfolioItemCard> createState() => _PortfolioItemCardState();
}

class _PortfolioItemCardState extends State<_PortfolioItemCard> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.item['images'] as List<String>;
    final bool hasMultipleImages = images.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.asset(
                        images[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  if (hasMultipleImages)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? widget.colors.primary
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  if (hasMultipleImages)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1}/${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.item['title']!,
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item['description']!,
                  style: AppTypography.body.copyWith(
                    color: widget.colors.textSecondary,
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
