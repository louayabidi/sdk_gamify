// lib/src/widgets/gamif_premium_streak_widget.dart
// 🔥 Premium Streak Widget with Particle Effects, Pulsing, & Tier-Based Theming

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tier enum + styling logic
// ═════════════════════════════════════════════════════════════════════════════

enum StreakTier { bronze, silver, gold, legendary }

class StreakTierStyle {
  final StreakTier tier;
  final Color primaryColor;
  final Color accentColor;
  final String label;
  final double glowIntensity;
  final bool hasShimmer;
  final bool hasRotatingBg;
  final String emoji;

  StreakTierStyle({
    required this.tier,
    required this.primaryColor,
    required this.accentColor,
    required this.label,
    required this.glowIntensity,
    required this.hasShimmer,
    required this.hasRotatingBg,
    required this.emoji,
  });

  static StreakTierStyle forDays(int days) {
    if (days >= 100) {
      return StreakTierStyle(
        tier: StreakTier.legendary,
        primaryColor: const Color(0xFFFF6B35),
        accentColor: const Color(0xFFFFD700),
        label: 'LEGENDARY',
        glowIntensity: 0.8,
        hasShimmer: true,
        hasRotatingBg: true,
        emoji: '⚡',
      );
    } else if (days >= 50) {
      return StreakTierStyle(
        tier: StreakTier.gold,
        primaryColor: const Color(0xFFF59E0B),
        accentColor: const Color(0xFFFFD700),
        label: 'GOLD',
        glowIntensity: 0.6,
        hasShimmer: true,
        hasRotatingBg: false,
        emoji: '👑',
      );
    } else if (days >= 14) {
      return StreakTierStyle(
        tier: StreakTier.silver,
        primaryColor: const Color(0xFF9CA3AF),
        accentColor: const Color(0xFFE5E7EB),
        label: 'SILVER',
        glowIntensity: 0.3,
        hasShimmer: false,
        hasRotatingBg: false,
        emoji: '✨',
      );
    } else {
      return StreakTierStyle(
        tier: StreakTier.bronze,
        primaryColor: const Color(0xFFB45309),
        accentColor: const Color(0xFFD97706),
        label: 'BRONZE',
        glowIntensity: 0.1,
        hasShimmer: false,
        hasRotatingBg: false,
        emoji: '🔥',
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Particle burst effect
// ═════════════════════════════════════════════════════════════════════════════

class Particle {
  late Offset position;
  late Offset velocity;
  late double scale;
  late double opacity;
  late double lifespan;
  late double age;
  final Color color;

  Particle({required this.color}) {
    final rng = Random();
    final angle = rng.nextDouble() * 2 * pi;
    final speed = 100 + rng.nextDouble() * 150;
    velocity = Offset(cos(angle) * speed, sin(angle) * speed);
    scale = 1.0;
    lifespan = 600; // ms
    age = 0;
    opacity = 1.0;
  }

  void update(double deltaMs) {
    age += deltaMs;
    position += velocity * (deltaMs / 1000);
    final progress = age / lifespan;
    opacity = (1.0 - progress).clamp(0, 1);
    scale = (1.0 - progress * 0.5).clamp(0.5, 1.0);
  }

  bool get isDead => age >= lifespan;
}

// ═════════════════════════════════════════════════════════════════════════════
// Particle burst painter
// ═════════════════════════════════════════════════════════════════════════════

class ParticleBurstPainter extends CustomPainter {
  final List<Particle> particles;

  ParticleBurstPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      canvas.saveLayer(null, Paint());
      canvas.drawCircle(
        center + p.position,
        4 * p.scale,
        Paint()
          ..color = p.color.withOpacity(p.opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticleBurstPainter oldDelegate) => true;
}

// ═════════════════════════════════════════════════════════════════════════════
// Counting Number Widget (animates when value changes)
// ═════════════════════════════════════════════════════════════════════════════

class AnimatedCountingNumber extends StatefulWidget {
  final int value;
  final TextStyle textStyle;
  final Duration duration;

  const AnimatedCountingNumber({
    super.key,
    required this.value,
    required this.textStyle,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedCountingNumber> createState() => _AnimatedCountingNumberState();
}

class _AnimatedCountingNumberState extends State<AnimatedCountingNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  late int _displayValue;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _setupAnimation();
  }

  void _setupAnimation() {
    _animation = IntTween(begin: _displayValue, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _animation.addListener(() {
      setState(() => _displayValue = _animation.value);
    });
  }

  @override
  void didUpdateWidget(AnimatedCountingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    '$_displayValue',
    style: widget.textStyle,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Shimmer effect (for gold/legendary tiers)
// ═════════════════════════════════════════════════════════════════════════════

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_controller.value - 0.2).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.2).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.4),
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Rotating gradient background (for legendary tiers)
// ═════════════════════════════════════════════════════════════════════════════

class RotatingGradientBg extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color color1;
  final Color color2;

  const RotatingGradientBg({
    super.key,
    required this.child,
    required this.color1,
    required this.color2,
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<RotatingGradientBg> createState() => _RotatingGradientBgState();
}

class _RotatingGradientBgState extends State<RotatingGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                cos(_controller.value * 2 * pi),
                sin(_controller.value * 2 * pi),
              ),
              end: Alignment(
                cos((_controller.value + 0.5) * 2 * pi),
                sin((_controller.value + 0.5) * 2 * pi),
              ),
              colors: [widget.color1, widget.color2],
            ),
          ),
          child: child,
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Premium Streak Card
// ═════════════════════════════════════════════════════════════════════════════

class PremiumStreakCard extends StatefulWidget {
  final UserStreakInfo streak;
  final Color textColor;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback? onStreakComplete; // Trigger particle burst

  const PremiumStreakCard({
    super.key,
    required this.streak,
    required this.textColor,
    required this.accentColor,
    required this.cardColor,
    this.onStreakComplete,
  });

  @override
  State<PremiumStreakCard> createState() => _PremiumStreakCardState();
}

class _PremiumStreakCardState extends State<PremiumStreakCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;
  List<Particle> particles = [];
  late Timer _particleTimer;
  bool _showParticleBurst = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for grace period
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Particle burst animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _particleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _particleController.stop();
        if (mounted) setState(() => _showParticleBurst = false);
      }
    });
  }

  @override
  void didUpdateWidget(PremiumStreakCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger burst on streak change or complete
    if (oldWidget.streak.currentStreak != widget.streak.currentStreak &&
        widget.streak.currentStreak > oldWidget.streak.currentStreak) {
      _triggerParticleBurst();
    }
  }

  void _triggerParticleBurst() {
    if (mounted) {
      setState(() => _showParticleBurst = true);
      particles = List.generate(
        20,
        (_) => Particle(
          color: const Color(0xFFFF6B35), // Orange/red sparks
        ),
      );
      particles.forEach((p) => p.position = Offset.zero);

      _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (mounted) {
          setState(() {
            for (final p in particles) {
              p.update(16.0);
            }
            particles.removeWhere((p) => p.isDead);
          });
        }
        if (particles.isEmpty) timer.cancel();
      });

      _particleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    _particleTimer.cancel();
    super.dispose();
  }

  bool get _isInGracePeriod => widget.streak.freezeTokens > 0;
  final style = StreakTierStyle.forDays(7); // Example: 7 days

  StreakTierStyle get _tierStyle =>
      StreakTierStyle.forDays(widget.streak.currentStreak);

  @override
  Widget build(BuildContext context) {
    final tierStyle = _tierStyle;
    final isLegendary = tierStyle.tier == StreakTier.legendary;
    final isGold = tierStyle.tier == StreakTier.gold;

    // Build base card with tier styling
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tierStyle.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tierStyle.primaryColor.withOpacity(0.3),
          width: tierStyle.tier == StreakTier.bronze ? 1.0 : 1.5,
        ),
        boxShadow: [
          if (tierStyle.glowIntensity > 0)
            BoxShadow(
              color: tierStyle.primaryColor.withOpacity(tierStyle.glowIntensity),
              blurRadius: 12 + (tierStyle.glowIntensity * 8),
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: name + freeze tokens ──
          Row(children: [
            Expanded(
              child: Text(
                widget.streak.streakName,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.streak.freezeTokens > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF87CEEB).withOpacity(0.3),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('❄️', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 3),
                  Text(
                    '${widget.streak.freezeTokens}',
                    style: const TextStyle(
                      color: Color(0xFF87CEEB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
          ]),
          const SizedBox(height: 10),

          // ── Main row: flame icon + stats + window badge ──
          Row(children: [
            // Flame icon with pulse if in grace period
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                double scale = _isInGracePeriod
                    ? 0.85 + _pulseController.value * 0.3
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tierStyle.primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: _isInGracePeriod
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF6B35)
                                    .withOpacity(0.5 * _pulseController.value),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      widget.streak.currentStreak > 0
                          ? tierStyle.emoji
                          : '💤',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),

            // Streak number + label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  AnimatedCountingNumber(
                    value: widget.streak.currentStreak,
                    textStyle: TextStyle(
                      color: tierStyle.primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'days',
                    style: TextStyle(
                      color: widget.textColor.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
                Text(
                  'Best: ${widget.streak.longestStreak} days',
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Tier badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tierStyle.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tierStyle.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                tierStyle.label,
                style: TextStyle(
                  color: tierStyle.primaryColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ]),
        ],
      ),
    );

    // Wrap with shimmer if gold/legendary
    if (isGold) {
      card = ShimmerEffect(child: card);
    }

    // Wrap with rotating gradient if legendary
    if (isLegendary) {
      card = RotatingGradientBg(
        color1: tierStyle.primaryColor.withOpacity(0.2),
        color2: tierStyle.accentColor.withOpacity(0.15),
        child: card,
      );
    }

    // Wrap with particle burst overlay
    if (_showParticleBurst) {
      card = Stack(
        children: [
          card,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ParticleBurstPainter(particles),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }
}