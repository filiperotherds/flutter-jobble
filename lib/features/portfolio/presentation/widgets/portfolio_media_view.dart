import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_models.dart';

/// Um trabalho do portfólio, desenhado conforme o formato escolhido.
///
/// Cada formato conta a história de um jeito: o carrossel mostra etapas, o
/// antes-e-depois mostra a diferença, a montagem mostra o conjunto num olhar
/// só. É o formato que manda, não a quantidade de fotos.
class PortfolioMediaView extends StatelessWidget {
  const PortfolioMediaView({super.key, required this.item, this.borderRadius});

  final PortfolioItem item;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    if (item.media.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(LucideIcons.image, color: Colors.grey, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: switch (item.kind) {
        PortfolioKind.beforeAfter => BeforeAfterView(item: item),
        PortfolioKind.collage => CollageView(media: item.media),
        PortfolioKind.carousel => CarouselView(media: item.media),
        PortfolioKind.video => PortfolioVideo(media: item.media.first),
        PortfolioKind.single => _Photo(url: item.media.first.fullUrl),
      },
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(LucideIcons.image_off, color: Colors.grey),
      ),
    );
  }
}

/// Antes e depois com régua arrastável.
///
/// Duas fotos empilhadas e um corte que a pessoa move com o dedo. Ver a mesma
/// parede mudar sob o próprio gesto convence mais do que duas fotos lado a
/// lado, onde o olho precisa fazer a comparação sozinho.
class BeforeAfterView extends StatefulWidget {
  const BeforeAfterView({super.key, required this.item});

  final PortfolioItem item;

  @override
  State<BeforeAfterView> createState() => _BeforeAfterViewState();
}

class _BeforeAfterViewState extends State<BeforeAfterView> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final before = widget.item.before ?? widget.item.media.first;
    final after = widget.item.after ?? widget.item.media.last;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _split = (details.localPosition.dx / width).clamp(0.0, 1.0);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Photo(url: after.fullUrl),
              // O "antes" fica por cima, recortado até a régua: arrastar
              // revela o depois que está embaixo.
              ClipRect(
                clipper: _LeftClipper(_split),
                child: _Photo(url: before.fullUrl),
              ),
              Positioned(
                left: width * _split - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: width * _split - 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.chevrons_left_right,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 10,
                bottom: 10,
                child: _Tag(text: 'ANTES'),
              ),
              const Positioned(
                right: 10,
                bottom: 10,
                child: _Tag(text: 'DEPOIS'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  const _LeftClipper(this.split);

  final double split;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * split, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.split != split;
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Montagem: várias fotos num quadro só.
///
/// O arranjo vem do app, não do profissional: duas fotos ficam lado a lado,
/// três ganham uma grande à esquerda, quatro formam um quadrado. Assim ele só
/// escolhe as fotos, e o resultado sai arrumado.
class CollageView extends StatelessWidget {
  const CollageView({super.key, required this.media, this.spacing = 2});

  final List<PortfolioMedia> media;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final photos = media.take(4).toList();

    return switch (photos.length) {
      0 => const SizedBox.shrink(),
      1 => _Photo(url: photos.first.fullUrl),
      2 => Row(
        children: [
          Expanded(child: _Photo(url: photos[0].fullUrl)),
          SizedBox(width: spacing),
          Expanded(child: _Photo(url: photos[1].fullUrl)),
        ],
      ),
      3 => Row(
        children: [
          Expanded(flex: 3, child: _Photo(url: photos[0].fullUrl)),
          SizedBox(width: spacing),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _Photo(url: photos[1].fullUrl)),
                SizedBox(height: spacing),
                Expanded(child: _Photo(url: photos[2].fullUrl)),
              ],
            ),
          ),
        ],
      ),
      _ => Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _Photo(url: photos[0].fullUrl)),
                SizedBox(width: spacing),
                Expanded(child: _Photo(url: photos[1].fullUrl)),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _Photo(url: photos[2].fullUrl)),
                SizedBox(width: spacing),
                Expanded(child: _Photo(url: photos[3].fullUrl)),
              ],
            ),
          ),
        ],
      ),
    };
  }
}

/// Carrossel: as fotos na ordem em que foram enviadas, com os pontinhos.
class CarouselView extends StatefulWidget {
  const CarouselView({super.key, required this.media});

  final List<PortfolioMedia> media;

  @override
  State<CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<CarouselView> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.media.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) =>
              _Photo(url: widget.media[index].fullUrl),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < widget.media.length; index++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _page
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vídeo do portfólio.
///
/// Começa parado, sem som e mostrando o primeiro quadro: uma grade de
/// trabalhos que dispara áudio sozinha é hostil para quem só está olhando.
class PortfolioVideo extends StatefulWidget {
  const PortfolioVideo({super.key, required this.media, this.autoPlay = false});

  final PortfolioMedia media;
  final bool autoPlay;

  @override
  State<PortfolioVideo> createState() => _PortfolioVideoState();
}

class _PortfolioVideoState extends State<PortfolioVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.media.fullUrl),
    );

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (widget.autoPlay) await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_failed) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: const Icon(LucideIcons.video_off, color: Colors.white54),
      );
    }

    if (controller == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() {
        controller.value.isPlaying ? controller.pause() : controller.play();
      }),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          if (!controller.value.isPlaying)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.play,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// O selo que a grade põe sobre a miniatura para dizer o formato.
class PortfolioKindBadge extends StatelessWidget {
  const PortfolioKindBadge({super.key, required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (item.kind) {
      PortfolioKind.carousel => (LucideIcons.copy, '${item.media.length}'),
      PortfolioKind.beforeAfter => (LucideIcons.chevrons_left_right, null),
      PortfolioKind.collage => (LucideIcons.layout_grid, null),
      PortfolioKind.video => (LucideIcons.play, null),
      PortfolioKind.single => (null, null),
    };

    if (icon == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: label == null ? 5 : 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          if (label != null) ...[
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A miniatura da grade: capa, selo do formato e, quando falta arquivo, o
/// aviso de que o trabalho ainda não está pronto para aparecer.
class PortfolioThumb extends StatelessWidget {
  const PortfolioThumb({super.key, required this.item, this.onTap});

  final PortfolioItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cover = item.fullCoverUrl;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover == null)
            Container(
              color: colors.surfaceLight,
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.image_plus,
                color: colors.textSecondary,
                size: 28,
              ),
            )
          else if (item.kind == PortfolioKind.collage)
            CollageView(media: item.media, spacing: 1)
          else
            _Photo(url: cover),

          if (item.kind == PortfolioKind.video)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.play,
                color: Colors.white,
                size: 26,
              ),
            ),

          Positioned(
            top: 6,
            right: 6,
            child: PortfolioKindBadge(item: item),
          ),

          if (item.incomplete)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Falta foto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
