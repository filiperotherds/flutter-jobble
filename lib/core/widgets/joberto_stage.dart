import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Fundo dos clipes do Joberto. As telas que mostram um clipe usam a mesma
/// cor, para o vídeo não aparecer como um retângulo.
const jobertoPaper = Color(0xFFF8F9F2);

/// Clipes animados do Joberto, cada um com a pose parada que o substitui
/// quando o vídeo não pode tocar.
///
/// Todos começam na pose do aceno, e os que repetem também terminam nela:
/// é isso que deixa um clipe emendar no outro sem salto.
enum JobertoClip {
  waving('joberto_wave', 'joberto_waving'),
  measuring('joberto_measure', 'joberto_thinking'),
  hiding('joberto_hide', 'joberto_thinking', loops: false),
  working('joberto_work', 'joberto_thinking'),
  puzzled('joberto_puzzled', 'joberto_thinking', loops: false),
  success('joberto_success', 'joberto_thumbsup', loops: false);

  const JobertoClip(String video, String still, {this.loops = true})
    : video = 'assets/videos/$video.mp4',
      still = 'assets/images/$still.png';

  final String video;
  final String still;

  /// Clipes que não repetem tocam uma vez e param no último quadro.
  final bool loops;

  /// O que o Joberto faz na tela de entrada, do mais urgente ao mais calmo.
  static JobertoClip forLogin({
    required bool submitting,
    required bool failed,
    required bool passwordFocused,
    required bool emailFocused,
  }) {
    if (submitting) return working;
    if (failed) return puzzled;
    if (passwordFocused) return hiding;
    if (emailFocused) return measuring;
    return waving;
  }
}

/// O Joberto animado.
///
/// Toca o vídeo do [clip]; enquanto ele carrega, se a plataforma não tocar
/// vídeo ou se o sistema pedir menos movimento, mostra a pose parada.
class JobertoStage extends StatefulWidget {
  const JobertoStage({
    super.key,
    required this.clip,
    this.height = 220,
    this.onCompleted,
  });

  final JobertoClip clip;
  final double height;

  /// Chamado quando um clipe que não repete chega ao fim.
  final VoidCallback? onCompleted;

  @override
  State<JobertoStage> createState() => _JobertoStageState();
}

class _JobertoStageState extends State<JobertoStage> {
  /// O clipe que está na tela. Na troca ele continua tocando até o próximo
  /// estar pronto, para o Joberto não piscar entre um e outro.
  VideoPlayerController? _showing;
  VideoPlayerController? _loading;

  /// O clipe que está saindo. Fica por baixo enquanto o novo aparece por cima,
  /// para a troca ser uma fusão e não um corte.
  VideoPlayerController? _leaving;
  bool _started = false;
  bool _completed = false;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!_reducedMotion) _load(widget.clip);
  }

  @override
  void didUpdateWidget(JobertoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip == widget.clip) return;
    if (!_reducedMotion) _load(widget.clip);
  }

  Future<void> _load(JobertoClip clip) async {
    final controller = VideoPlayerController.asset(
      clip.video,
      // O clipe é mudo: não deve pausar a música de quem está ouvindo algo.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _loading?.dispose();
    _loading = controller;

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(clip.loops);

      // Outro clipe foi pedido enquanto este carregava.
      if (!mounted || _loading != controller) return;

      // Uma troca no meio de outra: o que ainda estava saindo sai de vez.
      _leaving?.dispose();
      _completed = false;
      controller.addListener(_watchCompletion);
      setState(() {
        _leaving = _showing;
        _showing = controller;
        _loading = null;
      });
      await controller.play();
    } catch (_) {
      // Sem vídeo nesta plataforma: a pose parada continua no lugar.
    }
  }

  void _watchCompletion() {
    final controller = _showing;
    if (controller == null || _completed || widget.clip.loops) return;
    if (!controller.value.isCompleted) return;

    _completed = true;
    widget.onCompleted?.call();
  }

  void _finishCrossfade() {
    final leaving = _leaving;
    if (leaving == null) return;
    setState(() => _leaving = null);
    leaving.dispose();
  }

  @override
  void dispose() {
    _showing?.dispose();
    _leaving?.dispose();
    _loading?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _showing;
    final leaving = _leaving;

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (leaving != null)
            _CroppedVideo(key: ObjectKey(leaving), controller: leaving)
          else
            // Mesmo tamanho e posição que o personagem ocupa no vídeo, para
            // a troca da imagem pelo clipe não dar um salto.
            FractionallySizedBox(
              heightFactor: 0.88,
              alignment: const Alignment(0, 0.6),
              child: Image.asset(
                widget.clip.still,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          if (controller != null)
            TweenAnimationBuilder<double>(
              key: ObjectKey(controller),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOut,
              onEnd: _finishCrossfade,
              child: _CroppedVideo(controller: controller),
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
            ),
        ],
      ),
    );
  }
}

/// O vídeo sem as bordas: corta a marca d'água do rodapé e esmaece as
/// beiradas, para qualquer diferença de tom do fundo sumir na tela.
class _CroppedVideo extends StatelessWidget {
  const _CroppedVideo({super.key, required this.controller});

  final VideoPlayerController controller;

  static const _fade = [
    Colors.transparent,
    Colors.white,
    Colors.white,
    Colors.transparent,
  ];

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: _fade,
        stops: [0.0, 0.1, 0.9, 1.0],
      ).createShader(bounds),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _fade,
          stops: [0.0, 0.06, 0.96, 1.0],
        ).createShader(bounds),
        child: FittedBox(
          child: ClipRect(
            child: Align(
              alignment: const Alignment(0, 0.09),
              widthFactor: 0.84,
              heightFactor: 0.89,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
