import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Abertura animada com a logo, por cima do app.
///
/// Entra pelo `builder` do `MaterialApp`, e não como rota: o app monta por
/// baixo desde o primeiro frame, então a abertura não soma tempo à restauração
/// da sessão — ela só cobre a espera que já existia.
class JobbleSplash extends StatefulWidget {
  const JobbleSplash({
    super.key,
    required this.child,
    this.logoAsset = 'assets/images/logo-jobble.png',
  });

  final Widget child;
  final String logoAsset;

  static const layerKey = ValueKey<String>('jobble-splash');
  static const duration = Duration(milliseconds: 2500);

  @override
  State<JobbleSplash> createState() => _JobbleSplashState();
}

// Medidas em pixels do arquivo da logo (1080×341). Tudo é desenhado nesse
// espaço e escalado de uma vez, para os recortes baterem com o desenho.
const _logoW = 1080.0;
const _logoH = 341.0;
const _markCenter = Offset(103, 141);

/// Normal ao talho diagonal do símbolo, apontando para baixo e à direita.
const _slashNormal = Offset(0.659, 0.753);

/// Lado de baixo do talho: a meia-lua.
const _belowSlash = [
  Offset(-200, 380.5),
  Offset(240, -4.5),
  Offset(240, 700),
  Offset(-200, 700),
];

/// Lado de cima do talho: a gota.
const _aboveSlash = [
  Offset(-200, 380.5),
  Offset(240, -4.5),
  Offset(240, -400),
  Offset(-200, -400),
];

/// Faixas horizontais de cada letra de "jobble" ("le" vêm juntas no arquivo).
const _letters = [
  (340.0, 411.0),
  (411.0, 568.0),
  (568.0, 725.0),
  (725.0, 880.0),
  (880.0, 1080.0),
];

const _forest = Color(0xFF0D2F28);
const _lime = Color(0xFF9FE870);

class _JobbleSplashState extends State<JobbleSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: JobbleSplash.duration,
  );

  bool _started = false;
  bool _done = false;
  int _warmUpFrames = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _done = true;
      return;
    }

    // Já decodificada quando a animação pedir o primeiro quadro da logo.
    precacheImage(AssetImage(widget.logoAsset), context);
    SchedulerBinding.instance.scheduleFrameCallback(_warmUp);
  }

  /// O relógio da animação conta desde o primeiro tick, mas o primeiro quadro
  /// do app demora a chegar na tela — e até lá o Android ainda mostra a tela
  /// nativa por cima. Começando direto, a logo se animava inteira escondida.
  /// Alguns quadros de espera garantem que o Flutter já está visível.
  void _warmUp(Duration _) {
    if (!mounted) return;
    if (--_warmUpFrames > 0) {
      SchedulerBinding.instance.scheduleFrameCallback(_warmUp);
      return;
    }

    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AbsorbPointer(
          key: JobbleSplash.layerKey,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _SplashLayer(
              t: _controller.value,
              logoAsset: widget.logoAsset,
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashLayer extends StatelessWidget {
  const _SplashLayer({required this.t, required this.logoAsset});

  final double t;
  final String logoAsset;

  /// Progresso de um trecho da linha do tempo, já com a curva aplicada.
  double _span(double begin, double end, [Curve curve = Curves.linear]) {
    final raw = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  Widget _logo(Color color) {
    return Image.asset(
      logoAsset,
      width: _logoW,
      height: _logoH,
      fit: BoxFit.fill,
      color: color,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // As duas metades do símbolo saem de dentro do próprio talho.
    final moon = _span(0.06, 0.30, Curves.easeOutBack);
    final drop = _span(0.20, 0.42, Curves.easeOutBack);
    final pulse = math.sin(_span(0.42, 0.60) * math.pi);
    final ring = _span(0.44, 0.74, Curves.easeOut);
    // Recuo curto antes de abrir, para a revelação ter impulso.
    final windUp = _span(0.74, 0.82, Curves.easeIn);
    final reveal = _span(0.80, 1.0, Curves.easeInCubic);
    final logoFade = 1 - _span(0.80, 0.88);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final width = math.min(size.width * 0.62, 300.0);
        final scale = width / _logoW;
        final origin = Offset(
          (size.width - width) / 2,
          (size.height - _logoH * scale) / 2,
        );

        return CustomPaint(
          painter: _CurtainPainter(
            center: origin + _markCenter * scale,
            reveal: reveal,
          ),
          child: Center(
            child: Opacity(
              opacity: logoFade,
              child: Transform.scale(
                scale: 1 - 0.1 * windUp,
                child: SizedBox(
                  width: width,
                  child: FittedBox(
                    child: SizedBox(
                      width: _logoW,
                      height: _logoH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _RingPainter(ring)),
                          ),
                          Transform.scale(
                            scale: 1 + 0.12 * pulse,
                            alignment: Alignment(
                              _markCenter.dx / _logoW * 2 - 1,
                              _markCenter.dy / _logoH * 2 - 1,
                            ),
                            child: Stack(
                              children: [
                                ClipPath(
                                  clipper: const _PolygonClipper(_belowSlash),
                                  child: Transform.translate(
                                    offset: _slashNormal * (-130 * (1 - moon)),
                                    child: _logo(_lime),
                                  ),
                                ),
                                ClipPath(
                                  clipper: const _PolygonClipper(_aboveSlash),
                                  child: Transform.translate(
                                    offset: _slashNormal * (125 * (1 - drop)),
                                    child: _logo(_lime),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final (index, (left, right)) in _letters.indexed)
                            _Letter(
                              left: left,
                              right: right,
                              opacity: _span(
                                0.46 + index * 0.035,
                                0.56 + index * 0.035,
                              ),
                              rise: _span(
                                0.46 + index * 0.035,
                                0.64 + index * 0.035,
                                Curves.easeOutBack,
                              ),
                              child: _logo(Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.left,
    required this.right,
    required this.opacity,
    required this.rise,
    required this.child,
  });

  final double left;
  final double right;
  final double opacity;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 70 * (1 - rise)),
        child: ClipRect(
          clipper: _SliceClipper(left, right),
          child: child,
        ),
      ),
    );
  }
}

class _SliceClipper extends CustomClipper<Rect> {
  const _SliceClipper(this.left, this.right);

  final double left;
  final double right;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(left, -100, right, size.height + 100);

  @override
  bool shouldReclip(_SliceClipper oldClipper) =>
      oldClipper.left != left || oldClipper.right != right;
}

class _PolygonClipper extends CustomClipper<Path> {
  const _PolygonClipper(this.points);

  final List<Offset> points;

  @override
  Path getClip(Size size) => Path()..addPolygon(points, true);

  @override
  bool shouldReclip(_PolygonClipper oldClipper) => oldClipper.points != points;
}

/// Onda que sai do símbolo no momento do pulso.
class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    canvas.drawCircle(
      _markCenter,
      120 + 190 * progress,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - progress)
        ..color = _lime.withValues(alpha: 0.9 * (1 - progress)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Fundo da abertura, com o furo que cresce a partir do símbolo e revela o app.
class _CurtainPainter extends CustomPainter {
  const _CurtainPainter({required this.center, required this.reveal});

  final Offset center;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final curtain = Paint()..color = _forest;
    final bounds = Offset.zero & size;
    if (reveal <= 0) {
      canvas.drawRect(bounds, curtain);
      return;
    }

    final farthest = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ].map((corner) => (corner - center).distance).reduce(math.max);
    final radius = farthest * reveal;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(bounds),
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      ),
      curtain,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * (1 - reveal)
        ..color = _lime,
    );
  }

  @override
  bool shouldRepaint(_CurtainPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.reveal != reveal;
}
