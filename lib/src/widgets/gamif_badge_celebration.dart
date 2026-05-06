// lib/src/widgets/gamif_badge_celebration.dart
//
// Premium badge-unlock celebration — Apple Fitness inspired.
// Design philosophy: cinematic light reveal → badge emergence → meaning.
//
// Replaces cheap confetti + elastic pop with:
//   • Radial aurora glow that expands before the badge appears
//   • Ring self-draw (stroke dash animation)
//   • Shimmer sweep across the badge face
//   • Ambient light orbs drifting upward (soft, not chaotic)
//   • Editorial letter-spacing collapse on headline
//   • Coordinated 3-beat haptic pulse
//   • Cinematic scale+blur exit
//
// Zero external packages — pure Flutter.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class GamifBadgeCelebration extends StatefulWidget {
  final GamificationReward reward;
  final Color primaryColor;
  final Color accentColor;
  final VoidCallback onDismiss;

  const GamifBadgeCelebration({
    super.key,
    required this.reward,
    required this.primaryColor,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<GamifBadgeCelebration> createState() => _GamifBadgeCelebrationState();
}

class _GamifBadgeCelebrationState extends State<GamifBadgeCelebration>
    with TickerProviderStateMixin {

  // ── Phase controllers (each owns exactly one job) ─────────────────────────
  late final AnimationController _backdropCtrl;   // dark bg fade-in
  late final AnimationController _auroraCtrl;     // radial glow expand
  late final AnimationController _ringCtrl;       // arc self-draw
  late final AnimationController _badgeCtrl;      // badge scale + blur clear
  late final AnimationController _shimmerCtrl;    // highlight sweep (repeating)
  late final AnimationController _orbsCtrl;       // ambient orbs (repeating)
  late final AnimationController _textCtrl;       // headline + subtext
  late final AnimationController _pulseCtrl;      // subtle glow breathe (repeating)
  late final AnimationController _exitCtrl;       // whole scene exit

  // ── Derived animations ────────────────────────────────────────────────────
  late final Animation<double> _backdropFade;
  late final Animation<double> _auroraScale;
  late final Animation<double> _auroraFade;
  late final Animation<double> _ringProgress;   // 0→1 stroke dash
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeFade;
  late final Animation<double> _shimmerPos;     // -1→2 (off-left to off-right)
  late final Animation<double> _textFade;
  late final Animation<double> _letterSpacing;  // collapses from wide → tight
  late final Animation<double> _subtextSlide;
  late final Animation<double> _breatheScale;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  late final List<_Orb> _orbs;
  Timer? _autoDismiss;
  bool _dismissing = false;

  // ── Gold derived from accent (for the "earned" feeling) ──────────────────
  Color get _gold => Color.lerp(widget.accentColor, const Color(0xFFF5C842), 0.55)!;
  Color get _goldDim => _gold.withOpacity(0.35);

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _buildOrbs();
    _buildControllers();
    _startSequence();
  }

  void _buildOrbs() {
    final rng = Random();
    _orbs = List.generate(18, (_) => _Orb(rng, widget.accentColor, widget.primaryColor));
  }

  void _buildControllers() {
    // ── Backdrop ─────────────────────────────────────────────────────────
    _backdropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _backdropFade = CurvedAnimation(parent: _backdropCtrl, curve: Curves.easeOut);

    // ── Aurora (radial glow that precedes the badge) ──────────────────────
    _auroraCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _auroraScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _auroraCtrl, curve: Curves.easeOutCubic));
    _auroraFade  = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 60),
    ]).animate(_auroraCtrl);

    // ── Ring self-draw ────────────────────────────────────────────────────
    _ringCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 820));
    _ringProgress  = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut);

    // ── Badge ─────────────────────────────────────────────────────────────
    _badgeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _badgeScale = Tween<double>(begin: 0.60, end: 1.0).animate(
        CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOutBack));
    _badgeFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _badgeCtrl, curve: const Interval(0.0, 0.5)));

    // ── Shimmer (repeating highlight sweep) ───────────────────────────────
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(min: 0.0, max: 1.0);
    _shimmerPos  = Tween<double>(begin: -1.4, end: 2.4).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: const Interval(0.0, 0.6)));

    // ── Ambient orbs ──────────────────────────────────────────────────────
    _orbsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))
      ..repeat();

    // ── Text ──────────────────────────────────────────────────────────────
    _textCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _textFade      = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _letterSpacing = Tween<double>(begin: 14.0, end: 1.5).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _subtextSlide  = Tween<double>(begin: 14.0, end: 0.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    // ── Breathe (subtle badge glow pulse) ────────────────────────────────
    _pulseCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _breatheScale = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Exit ──────────────────────────────────────────────────────────────
    _exitCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _exitScale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _exitFade  = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
  }

  Future<void> _startSequence() async {
    // Beat 1 — backdrop + aurora
    HapticFeedback.lightImpact();
    _backdropCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 60));
    _orbsCtrl.forward();
    _auroraCtrl.forward();

    // Beat 2 — ring draws itself
    await Future.delayed(const Duration(milliseconds: 260));
    HapticFeedback.mediumImpact();
    _ringCtrl.forward();

    // Beat 3 — badge emerges from the glow
    await Future.delayed(const Duration(milliseconds: 320));
    _badgeCtrl.forward();

    // Beat 4 — text arrives
    await Future.delayed(const Duration(milliseconds: 340));
    HapticFeedback.heavyImpact();
    _textCtrl.forward();

    _autoDismiss = Timer(const Duration(seconds: 6), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _autoDismiss?.cancel();
    await _exitCtrl.forward();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _backdropCtrl.dispose();
    _auroraCtrl.dispose();
    _ringCtrl.dispose();
    _badgeCtrl.dispose();
    _shimmerCtrl.dispose();
    _orbsCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    _autoDismiss?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_backdropFade, _exitFade, _exitScale]),
      builder: (_, child) => Opacity(
        opacity: (_backdropFade.value * _exitFade.value).clamp(0.0, 1.0),
        child: Transform.scale(scale: _exitScale.value, child: child),
      ),
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // Deep, near-black with very subtle warm tint — not pure black
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.15),
              radius: 1.2,
              colors: [Color(0xFF1A1510), Color(0xFF0A0906)],
            ),
          ),
          child: Stack(
            children: [
              // ── Ambient orbs (background layer) ────────────────────────
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _orbsCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _OrbsPainter(orbs: _orbs, t: _orbsCtrl.value, screenSize: size),
                    ),
                  ),
                ),
              ),

              // ── Aurora glow behind badge ────────────────────────────────
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_auroraCtrl, _pulseCtrl]),
                  builder: (_, __) => Transform.translate(
                    offset: const Offset(0, -60),
                    child: Opacity(
                      opacity: _auroraFade.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _auroraScale.value * _breatheScale.value,
                        child: Container(
                          width: 340,
                          height: 340,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _gold.withOpacity(0.22),
                                widget.accentColor.withOpacity(0.12),
                                widget.primaryColor.withOpacity(0.06),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.38, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Center content ──────────────────────────────────────────
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBadgeStack(),
                      const SizedBox(height: 40),
                      _buildText(),
                      const SizedBox(height: 48),
                      _buildDismissButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Badge stack: ring → badge → shimmer ───────────────────────────────────

  Widget _buildBadgeStack() {
    final imageUrl = widget.reward.badgeImageUrl;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _ringCtrl, _badgeCtrl, _shimmerCtrl, _pulseCtrl,
      ]),
      builder: (_, __) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft outer glow (breathing)
              Transform.scale(
                scale: _breatheScale.value,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.18 * _badgeFade.value),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Ring self-draw
              CustomPaint(
                painter: _RingPainter(
                  progress: _ringProgress.value,
                  color: _gold,
                  strokeWidth: 1.8,
                  radius: 96,
                ),
                size: const Size(200, 200),
              ),

              // 3. Inner tick marks (static, appear with ring)
              Opacity(
                opacity: ((_ringProgress.value - 0.7) / 0.3).clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: _TickMarksPainter(color: _goldDim, count: 12, radius: 96),
                  size: const Size(200, 200),
                ),
              ),

              // 4. Badge circle
              Transform.scale(
                scale: _badgeScale.value * _breatheScale.value,
                child: Opacity(
                  opacity: _badgeFade.value.clamp(0.0, 1.0),
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Subtle metallic gradient
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.4),
                        radius: 0.9,
                        colors: [
                          Color.lerp(Colors.white, _gold, 0.12)!.withOpacity(0.18),
                          _gold.withOpacity(0.06),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: _gold.withOpacity(0.55),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withOpacity(0.30),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.20),
                          blurRadius: 48,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Badge image or fallback
                          (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Text('🏅', style: TextStyle(fontSize: 52)),
                                )
                              : const Text('🏅', style: TextStyle(fontSize: 52)),

                          // Shimmer highlight sweep
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ShimmerPainter(position: _shimmerPos.value),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Text block ─────────────────────────────────────────────────────────────
  //
  // Wrapped in Material(transparency) so Flutter never inherits the default
  // underline decoration from a missing Material ancestor.

  Widget _buildText() {
    final name = (widget.reward.badgeName?.isNotEmpty == true)
        ? widget.reward.badgeName!
        : (widget.reward.message.isNotEmpty ? widget.reward.message : 'New Achievement');

    return AnimatedBuilder(
      animation: _textCtrl,
      builder: (_, __) {
        final fade  = _textFade.value.clamp(0.0, 1.0);
        final slide = _subtextSlide.value;
        final ls    = _letterSpacing.value;

        return Material(
          type : MaterialType.transparency,
          child: Opacity(
            opacity: fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Eyebrow: animated letter-spacing collapse ─────────────
                Transform.translate(
                  offset: Offset(0, slide * 0.5),
                  child: Text(
                    'ACHIEVEMENT UNLOCKED',
                    style: TextStyle(
                      color          : _gold.withOpacity(0.60),
                      fontSize       : 9.5,
                      fontWeight     : FontWeight.w600,
                      letterSpacing  : ls,
                      height         : 1.0,
                      decoration     : TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Gold micro-divider — two dots flanking a thin line ────
                Transform.translate(
                  offset: Offset(0, slide * 0.3),
                  child: Row(
                    mainAxisSize    : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width : 4, height: 4,
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width : 52, height: 0.6,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            _gold.withOpacity(0.35),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                      Container(
                        width : 4, height: 4,
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Badge name — large, confident, no decoration ──────────
                Transform.translate(
                  offset: Offset(0, slide),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color          : Color(0xF5FFFFFF),
                        fontSize       : 24,
                        fontWeight     : FontWeight.w700,
                        height         : 1.28,
                        letterSpacing  : -0.4,
                        decoration     : TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Dismiss button ─────────────────────────────────────────────────────────

  Widget _buildDismissButton() {
    return AnimatedBuilder(
      animation: _textCtrl,
      builder: (_, __) => Material(
        type : MaterialType.transparency,
        child: Opacity(
          opacity: _textFade.value.clamp(0.0, 1.0),
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
              decoration: BoxDecoration(
                border      : Border.all(color: _gold.withOpacity(0.45), width: 1.0),
                borderRadius: BorderRadius.circular(50),
                color       : Colors.white.withOpacity(0.05),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  color          : _gold,
                  fontSize       : 14,
                  fontWeight     : FontWeight.w500,
                  letterSpacing  : 1.2,
                  decoration     : TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring self-draw painter
// Draws a partial arc that grows from 0 → full circle as [progress] → 1
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double radius;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final sweep = progress * 2 * pi;
    const startAngle = -pi / 2; // top

    // Glow pass
    canvas.drawArc(
      rect, startAngle, sweep, false,
      Paint()
        ..color = color.withOpacity(0.25 * progress)
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main ring — gradient via shader
    final shader = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweep,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.85),
        color,
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);

    canvas.drawArc(
      rect, startAngle, sweep, false,
      Paint()
        ..shader = shader
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Leading dot
    if (progress > 0.02) {
      final dotAngle = startAngle + sweep;
      final dx = cx + cos(dotAngle) * radius;
      final dy = cy + sin(dotAngle) * radius;
      canvas.drawCircle(Offset(dx, dy), strokeWidth * 1.4, Paint()..color = color);
      // Dot glow
      canvas.drawCircle(
        Offset(dx, dy), strokeWidth * 3,
        Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tick marks (appear after ring completes)
// ─────────────────────────────────────────────────────────────────────────────

class _TickMarksPainter extends CustomPainter {
  final Color color;
  final int count;
  final double radius;

  const _TickMarksPainter({
    required this.color,
    required this.count,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = color..strokeWidth = 1.0..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi - pi / 2;
      final inner = radius - 5;
      final outer = radius + 2;
      canvas.drawLine(
        Offset(cx + cos(angle) * inner, cy + sin(angle) * inner),
        Offset(cx + cos(angle) * outer, cy + sin(angle) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickMarksPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer sweep — diagonal highlight that slides across the badge
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double position; // -1.4 → 2.4

  const _ShimmerPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final x = position * w;
    const angle = -pi / 5; // ~36° tilt

    final shader = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.14),
        Colors.white.withOpacity(0.28),
        Colors.white.withOpacity(0.14),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    ).createShader(Rect.fromLTWH(x - w * 0.4, 0, w * 0.8, h));

    final path = Path()
      ..moveTo(x + h * tan(angle), 0)
      ..lineTo(x + h * tan(angle) + w * 0.5, 0)
      ..lineTo(x + w * 0.5, h)
      ..lineTo(x, h)
      ..close();

    canvas.drawPath(path, Paint()..shader = shader..blendMode = BlendMode.srcOver);
  }

  @override
  bool shouldRepaint(_ShimmerPainter o) => o.position != position;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient orbs — soft glowing particles that drift upward slowly
// Much more premium than confetti: they feel like light, not celebration trash
// ─────────────────────────────────────────────────────────────────────────────

class _Orb {
  final double x;      // normalized 0–1
  final double yStart; // normalized 0.4–1.1 (below center)
  final double speed;  // normalized 0.25–0.55
  final double size;
  final double opacity;
  final Color  color;
  final double delay;  // 0–1 phase offset so they don't all move in sync
  final double wobble; // horizontal drift amplitude

  _Orb(Random rng, Color accent, Color primary)
      : x       = 0.1 + rng.nextDouble() * 0.8,
        yStart  = 0.55 + rng.nextDouble() * 0.45,
        speed   = 0.22 + rng.nextDouble() * 0.30,
        size    = 3.0 + rng.nextDouble() * 14.0,
        opacity = 0.06 + rng.nextDouble() * 0.18,
        color   = rng.nextBool() ? accent : primary,
        delay   = rng.nextDouble(),
        wobble  = (rng.nextDouble() - 0.5) * 0.04;
}

class _OrbsPainter extends CustomPainter {
  final List<_Orb> orbs;
  final double t;          // 0–1, repeating
  final Size screenSize;

  const _OrbsPainter({
    required this.orbs,
    required this.t,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite  ? size.width  : screenSize.width;
    final h = size.height.isFinite ? size.height : screenSize.height;

    for (final orb in orbs) {
      // Each orb has its own phase loop
      final phase = (t + orb.delay) % 1.0;
      final dy    = phase * orb.speed;

      // Normalized y: starts at yStart, drifts upward
      final ny = orb.yStart - dy;
      if (ny < -0.05) continue; // off screen top

      // Fade in near bottom, fade out near top
      final alpha = ny < 0.1
          ? (ny / 0.1).clamp(0.0, 1.0)
          : ny > 0.9
              ? ((1.0 - ny) / 0.1).clamp(0.0, 1.0)
              : 1.0;

      final px = (orb.x + sin(phase * 2 * pi) * orb.wobble) * w;
      final py = ny * h;

      canvas.drawCircle(
        Offset(px, py),
        orb.size * 0.5,
        Paint()
          ..color = orb.color.withOpacity(orb.opacity * alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.size * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbsPainter o) => o.t != t;
}