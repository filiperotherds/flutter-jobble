import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_api.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_models.dart';
import 'package:flutter_tcc/features/portfolio/presentation/pages/portfolio_detail_page.dart';
import 'package:flutter_tcc/features/portfolio/presentation/widgets/new_portfolio_sheet.dart';
import 'package:flutter_tcc/features/portfolio/presentation/widgets/portfolio_media_view.dart';

/// O portfólio do profissional, em grade.
///
/// Antes era uma lista de cards grandes: com dez trabalhos a tela virava uma
/// rolagem infinita e nenhum trabalho era visto junto dos outros. A grade
/// mostra o conjunto de uma vez — é assim que se olha o trabalho de alguém — e
/// o card inteiro fica para quando a pessoa escolhe um.
class ProviderPortfolioPage extends StatefulWidget {
  const ProviderPortfolioPage({super.key});

  @override
  State<ProviderPortfolioPage> createState() => _ProviderPortfolioPageState();
}

class _ProviderPortfolioPageState extends State<ProviderPortfolioPage> {
  final _api = PortfolioApi();

  List<PortfolioItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.mine();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _open(PortfolioItem item) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PortfolioDetailPage(
          item: item,
          onDelete: () => _api.remove(item.id),
        ),
      ),
    );

    if (deleted == true && mounted) _load();
  }

  Future<void> _create() async {
    final created = await NewPortfolioSheet.show(context);
    if (created == true && mounted) _load();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty ? _empty(colors) : _grid(colors),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Novo Projeto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _grid(AppColorsTheme colors) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(
              _items.length == 1
                  ? '1 trabalho publicado'
                  : '${_items.length} trabalhos publicados',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          // Sem folga lateral: a grade encosta nas bordas, como numa galeria.
          padding: const EdgeInsets.only(bottom: 96),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => PortfolioThumb(
                item: _items[index],
                onTap: () => _open(_items[index]),
              ),
              childCount: _items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(AppColorsTheme colors) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        const SizedBox(height: 40),
        Icon(LucideIcons.image_plus, size: 48, color: colors.borderLight),
        const SizedBox(height: AppSpacing.md),
        Text(
          _error ?? 'Seu portfólio está vazio',
          textAlign: TextAlign.center,
          style: AppTypography.h3.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Quem está escolhendo um profissional olha o trabalho antes do '
          'preço. Um antes e depois costuma valer mais que uma foto solta.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
