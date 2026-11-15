import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Fundo dos clipes do Joberto. As telas que mostram um clipe usam a mesma
/// cor, para o vídeo não aparecer como um retângulo.
const jobertoPaper = Color(0xFFF8F9F2);

/// Um trecho de vídeo do Joberto.
@immutable
class JobertoSegment {
  const JobertoSegment(this.asset, {this.loops = false});

  final String asset;

  /// Repete até outro trecho tomar o lugar.
  final bool loops;

  @override
  bool operator ==(Object other) =>
      other is JobertoSegment && other.asset == asset && other.loops == loops;

  @override
  int get hashCode => Object.hash(asset, loops);

  @override
  String toString() => 'JobertoSegment($asset, loops: $loops)';
}

/// O que o Joberto está fazendo, com a pose parada que o substitui quando o
/// vídeo não pode tocar.
///
/// Cada gesto é feito de até três trechos: a entrada, que sai do aceno e chega
/// na ação; o ciclo, que repete a ação sem emenda; e a saída, que volta ao
/// aceno. Os arquivos saem de `tool/joberto/build_clips.py`.
enum JobertoClip {
  waving(still: 'joberto_waving', loop: 'wave_loop'),
  measuring(
    still: 'joberto_thinking',
    intro: 'measure_in',
    cut: 'measure_cut',
    loop: 'measure_loop',
    outro: 'measure_out',
  ),
  hiding(
    still: 'joberto_thinking',
    intro: 'hide_in',
    cut: 'hide_cut',
    loop: 'hide_loop',
    outro: 'hide_out',
  ),
  working(
    still: 'joberto_thinking',
    intro: 'work_in',
    cut: 'work_cut',
    loop: 'work_loop',
    outro: 'work_out',
  ),
  puzzled(still: 'joberto_thinking', intro: 'puzzled'),
  success(still: 'joberto_thumbsup', intro: 'success');

  const JobertoClip({
    required String still,
    String? intro,
    String? cut,
    String? loop,
    String? outro,
  }) : still = 'assets/images/$still.png',
       _intro = intro,
       _cut = cut,
       _loop = loop,
       _outro = outro;

  final String still;
  final String? _intro;

  /// A entrada sem o começo, em que o Joberto ainda baixa o braço do aceno.
  /// É a que serve para quem chega de outro gesto.
  final String? _cut;
  final String? _loop;
  final String? _outro;

  /// Fica na ação até mudar; os outros tocam uma vez e avisam que acabaram.
  bool get loops => _loop != null;

  static String _path(String name) => 'assets/videos/joberto_$name.mp4';

  /// Os trechos que levam o Joberto de [from] até este gesto.
  ///
  /// De volta ao aceno, ele guarda o que estava usando antes de acenar. Entre
  /// dois gestos, entra no novo já sem o começo, que mostraria um aceno que
  /// ele não estava fazendo.
  List<JobertoSegment> sequence({JobertoClip? from}) {
    final outro = from?._outro;
    if (this == waving && outro != null) {
      return [
        JobertoSegment(_path(outro)),
        JobertoSegment(_path(_loop!), loops: true),
      ];
    }

    final busy = from != null && from != waving;
    final intro = busy ? _cut ?? _intro : _intro;
    return [
      if (intro != null) JobertoSegment(_path(intro)),
      if (_loop case final loop?) JobertoSegment(_path(loop), loops: true),
    ];
  }

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
/// Toca os trechos do [clip] em sequência; enquanto o vídeo carrega, se a
/// plataforma não tocar vídeo ou se o sistema pedir menos movimento, mostra a
/// pose parada.
class JobertoStage extends StatefulWidget {
  const JobertoStage({
    super.key,
    required this.clip,
    this.height = 220,
    this.stillWhileLoading = true,
    this.onCompleted,
  });

  final JobertoClip clip;
  final double height;

  /// Mostra a pose parada enquanto o vídeo carrega. Desligado, ela só aparece
  /// se o vídeo não puder tocar — para gestos cuja pose parada é o fim do
  /// movimento, e que por isso dariam um salto ao trocar pelo vídeo.
  final bool stillWhileLoading;

  /// Chamado quando um gesto que não repete chega ao fim.
  final VoidCallback? onCompleted;

  @override
  State<JobertoStage> createState() => _JobertoStageState();
}

class _JobertoStageState extends State<JobertoStage> {
  /// Troca entre gestos diferentes: uma fusão, porque as poses não batem.
  static const _crossfade = Duration(milliseconds: 320);

  /// Troca entre trechos do mesmo gesto: o quadro é o mesmo dos dois lados,
  /// então basta o tempo de o vídeo novo aparecer.
  static const _cut = Duration(milliseconds: 90);

  /// O vídeo avisa a posição em intervalos; este é o quanto antes do fim a
  /// troca pode acontecer sem pular movimento que dê para notar.
  static const _endSlack = Duration(milliseconds: 110);

  VideoPlayerController? _showing;

  /// O trecho que está saindo. Fica por baixo enquanto o novo aparece.
  VideoPlayerController? _leaving;

  /// O próximo trecho da sequência, carregado enquanto o atual ainda toca.
  VideoPlayerController? _pending;

  Duration _fade = _crossfade;

  /// Muda a cada sequência nova; quem estava esperando uma antiga desiste.
  int _ticket = 0;
  bool _started = false;

  /// O vídeo não tocou nesta plataforma: fica a pose parada.
  bool _videoFailed = false;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!_reducedMotion) _run(widget.clip.sequence());
  }

  @override
  void didUpdateWidget(JobertoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip == widget.clip) return;
    if (!_reducedMotion) _run(widget.clip.sequence(from: oldWidget.clip));
  }

  Future<void> _run(List<JobertoSegment> segments) async {
    final ticket = ++_ticket;
    _pending?.dispose();
    _pending = null;

    var fade = _crossfade;
    VideoPlayerController? previous;

    for (final segment in segments) {
      final controller = await _prepare(segment);
      if (!mounted || ticket != _ticket) {
        controller?.dispose();
        return;
      }
      // Sem vídeo nesta plataforma: fica o que já estava na tela.
      if (controller == null) {
        setState(() => _videoFailed = true);
        return;
      }

      if (previous != null) {
        _pending = controller;
        await _finished(previous);
        // Quem trocou a sequência já descartou o que estava pendente.
        if (!mounted || ticket != _ticket) return;
        _pending = null;
      }

      _show(controller, fade);
      fade = _cut;
      previous = controller;
    }

    if (previous == null || segments.last.loops) return;
    await _finished(previous);
    if (mounted && ticket == _ticket) widget.onCompleted?.call();
  }

  Future<VideoPlayerController?> _prepare(JobertoSegment segment) async {
    final controller = VideoPlayerController.asset(
      segment.asset,
      // O clipe é mudo: não deve pausar a música de quem está ouvindo algo.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(segment.loops);
      return controller;
    } catch (_) {
      controller.dispose();
      return null;
    }
  }

  /// Completa quando o trecho chega ao fim. Se ele for descartado antes,
  /// nunca completa — e quem esperava já não está mais na vez.
  Future<void> _finished(VideoPlayerController controller) {
    final done = Completer<void>();

    void check() {
      final value = controller.value;
      final ended =
          value.isCompleted ||
          (value.duration > Duration.zero &&
              value.duration - value.position <= _endSlack);
      if (!ended) return;
      controller.removeListener(check);
      if (!done.isCompleted) done.complete();
    }

    controller.addListener(check);
    check();
    return done.future;
  }

  void _show(VideoPlayerController controller, Duration fade) {
    // Uma troca no meio de outra: o que ainda estava saindo sai de vez.
    final stale = _leaving;
    setState(() {
      _leaving = _showing;
      _showing = controller;
      _fade = fade;
    });
    _discard(stale);
    controller.play();
  }

  void _finishFade() {
    final leaving = _leaving;
    if (leaving == null) return;
    setState(() => _leaving = null);
    _discard(leaving);
  }

  /// Libera um vídeo que acabou de sair da tela. Espera o quadro em que ele
  /// some, para nada desenhar um vídeo já liberado.
  void _discard(VideoPlayerController? controller) {
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  @override
  void dispose() {
    _ticket++;
    _showing?.dispose();
    _leaving?.dispose();
    _pending?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _showing;
    final leaving = _leaving;
    final showStill =
        widget.stillWhileLoading || _videoFailed || _reducedMotion;

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (leaving != null)
            _Video(key: ObjectKey(leaving), controller: leaving)
          else if (showStill)
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
              duration: _fade,
              curve: Curves.easeInOut,
              onEnd: _finishFade,
              child: _Video(controller: controller),
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
            ),
        ],
      ),
    );
  }
}

/// O vídeo com as beiradas esmaecidas: o fundo já vem na cor da tela, e isto
/// cobre a pequena diferença de tom que o decodificador de cada aparelho pode
/// introduzir.
class _Video extends StatelessWidget {
  const _Video({super.key, required this.controller});

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
        stops: [0.0, 0.05, 0.95, 1.0],
      ).createShader(bounds),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _fade,
          stops: [0.0, 0.03, 0.98, 1.0],
        ).createShader(bounds),
        child: FittedBox(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
