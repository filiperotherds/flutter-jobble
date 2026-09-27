import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_api.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_models.dart';

/// Escolher um trabalho do portfólio para ser a capa do perfil.
///
/// Mesma grade da galeria do portfólio, porque é a mesma coisa sendo olhada:
/// as fotos que ele já publicou. Devolve a URL escolhida para quem abriu.
class ProfileCoverPage extends StatefulWidget {
  const ProfileCoverPage({super.key, this.currentCoverUrl});

  /// A capa de hoje, para marcar qual foto já está escolhida.
  final String? currentCoverUrl;

  @override
  State<ProfileCoverPage> createState() => _ProfileCoverPageState();
}

class _ProfileCoverPageState extends State<ProfileCoverPage> {
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
      final items = await PortfolioApi().mine();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  /// Todas as fotos publicadas, numa lista só. Vídeo fica de fora: uma capa é
  /// uma imagem parada.
  List<PortfolioMedia> get _photos => [
    for (final item in _items)
      for (final media in item.media)
        if (!media.isVideo) media,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final photos = _photos;

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
          'Escolher do Portfólio',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : photos.isEmpty
          ? _empty(colors)
          : GridView.builder(
              // Sem folga lateral: a grade encosta nas bordas, como na
              // galeria do portfólio.
              padding: EdgeInsets.zero,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final media = photos[index];
                final isCurrent = media.url == widget.currentCoverUrl;

                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(media.url),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        media.fullUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: colors.surfaceLight),
                      ),
                      if (isCurrent)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.primary, width: 3),
                          ),
                          alignment: Alignment.bottomRight,
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _empty(AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.image, size: 48, color: colors.borderLight),
          const SizedBox(height: AppSpacing.md),
          Text(
            _error ?? 'Você ainda não publicou fotos no portfólio',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Publique um trabalho e ele pode virar a capa do seu perfil.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
