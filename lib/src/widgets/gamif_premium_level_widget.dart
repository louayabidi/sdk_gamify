// lib/src/widgets/gamif_premium_level_widget.dart
// 🎖️ Premium Level Widget with Counting & Progressive Unlocks

import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Level Tier System (visual progression)
// ═════════════════════════════════════════════════════════════════════════════

enum LevelTier { rookie, explorer, veteran, legend, champion }

class LevelTierStyle {
  final LevelTier tier;
  final Color accentColor;
  final Color glowColor;
  final double glowIntensity;
  final String emoji;
  final Gradient backgroundGradient;

  LevelTierStyle({
    required this.tier,
    required this.accentColor,
    required this.glowColor,
    required this.glowIntensity,
    required this.emoji,
    required this.backgroundGradient,
  });

  static LevelTierStyle forLevel(int level) {
    if (level >= 50) {
      // Champion: Bright gold with celestial glow
      return LevelTierStyle(
        tier: LevelTier.champion,
        accentColor: const Color(0xFFFFD700),
        glowColor: const Color(0xFFFFA500),
        glowIntensity: 1.0,
        emoji: '👑',
        backgroundGradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.15),
            const Color(0xFFFFA500).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (level >= 30) {
      // Legend: Purple/gold combo
      return LevelTierStyle(
        tier: LevelTier.legend,
        accentColor: const Color(0xFF9D4EDD),
        glowColor: const Color(0xFF5A189A),
        glowIntensity: 0.8,
        emoji: '⚡',
        backgroundGradient: LinearGradient(
          colors: [
            const Color(0xFF9D4EDD).withOpacity(0.12),
            const Color(0xFF5A189A).withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (level >= 15) {
      // Veteran: Silver/cyan
      return LevelTierStyle(
        tier: LevelTier.veteran,
        accentColor: const Color(0xFF4DD0E1),
        glowColor: const Color(0xFF00838F),
        glowIntensity: 0.5,
        emoji: '✨',
        backgroundGradient: LinearGradient(
          colors: [
            const Color(0xFF4DD0E1).withOpacity(0.12),
            const Color(0xFF00838F).withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (level >= 5) {
      // Explorer: Teal/blue
      return LevelTierStyle(
        tier: LevelTier.explorer,
        accentColor: const Color(0xFF1E88E5),
        glowColor: const Color(0xFF0D47A1),
        glowIntensity: 0.3,
        emoji: '🚀',
        backgroundGradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withOpacity(0.1),
            const Color(0xFF0D47A1).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else {
      // Rookie: Simple blue
      return LevelTierStyle(
        tier: LevelTier.rookie,
        accentColor: const Color(0xFF42A5F5),
        glowColor: const Color(0xFF1976D2),
        glowIntensity: 0.1,
        emoji: '🌱',
        backgroundGradient: LinearGradient(
          colors: [
            const Color(0xFF42A5F5).withOpacity(0.08),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Animated Progress Bar with smooth filling
// ═════════════════════════════════════════════════════════════════════════════

class AnimatedProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color fillColor;
  final Color backgroundColor;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.fillColor,
    required this.backgroundColor,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _setupAnimation();
    _controller.forward();
  }

  void _setupAnimation() {
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _controller.reset();
      _setupAnimation();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(children: [
            // Background track
            Container(
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // Animated fill
            FractionallySizedBox(
              widthFactor: _animation.value.clamp(0.0, 1.0),
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    widget.fillColor,
                    Color.lerp(widget.fillColor, Colors.white, 0.3)!,
                  ]),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: widget.fillColor.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// XP Counter with rolling numbers
// ═════════════════════════════════════════════════════════════════════════════

class XPCounter extends StatefulWidget {
  final int currentXp;
  final int nextThreshold;
  final TextStyle textStyle;

  const XPCounter({
    super.key,
    required this.currentXp,
    required this.nextThreshold,
    required this.textStyle,
  });

  @override
  State<XPCounter> createState() => _XPCounterState();
}

class _XPCounterState extends State<XPCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _currentXpAnim;
  late int _displayXp;

  @override
  void initState() {
    super.initState();
    _displayXp = widget.currentXp;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _setupAnimation();
  }

  void _setupAnimation() {
    _currentXpAnim =
        IntTween(begin: _displayXp, end: widget.currentXp).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _currentXpAnim.addListener(() {
      setState(() => _displayXp = _currentXpAnim.value);
    });
  }

  @override
  void didUpdateWidget(XPCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXp != widget.currentXp) {
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
    '$_displayXp / ${widget.nextThreshold} XP',
    style: widget.textStyle,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Premium Level Card
// ═════════════════════════════════════════════════════════════════════════════

class PremiumLevelCard extends StatefulWidget {
  final UserLevelInfo level;
  final Color textColor;
  final String? titleOverride;

  const PremiumLevelCard({
    super.key,
    required this.level,
    required this.textColor,
    this.titleOverride,
  });

  @override
  State<PremiumLevelCard> createState() => _PremiumLevelCardState();
}

class _PremiumLevelCardState extends State<PremiumLevelCard>
    with TickerProviderStateMixin {
  late AnimationController _levelUpController;
  late AnimationController _glowController;
  bool _wasLevelUp = false;

  @override
  void initState() {
    super.initState();

    // Level-up animation (pop effect)
    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Glow pulse (continuous for higher tiers)
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _checkLevelUp();
  }

  void _checkLevelUp() {
    final tierStyle = LevelTierStyle.forLevel(widget.level.currentLevel);
    if (tierStyle.glowIntensity > 0.5) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PremiumLevelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level.currentLevel != widget.level.currentLevel) {
      _levelUpController.forward(from: 0);
      _wasLevelUp = true;
    }
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

@override
Widget build(BuildContext context) {
  final tierStyle = LevelTierStyle.forLevel(widget.level.currentLevel);

  return AnimatedBuilder(
    animation: _glowController,
    builder: (context, child) {
      final intensity = _glowController.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: tierStyle.backgroundGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tierStyle.accentColor.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tierStyle.glowColor.withOpacity(
                (0.2 + intensity * 0.2) * tierStyle.glowIntensity,
              ),
              blurRadius: 8 + (intensity * 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: child, 
      );
    },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: level name + title badge ──
          Row(children: [
            Expanded(
              child: Text(
                widget.level.levelName,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.titleOverride != null &&
                widget.titleOverride!.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tierStyle.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tierStyle.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.titleOverride!,
                  style: TextStyle(
                    color: tierStyle.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),

          // ── Main row: level circle + XP bar ──
          Row(children: [
            // Animated level circle (pops on level-up)
            AnimatedBuilder(
              animation: _levelUpController,
              builder: (context, child) {
                double scale = 1.0;
                if (_wasLevelUp) {
                  scale = 1.0 + (_levelUpController.value * 0.15);
                }
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    tierStyle.accentColor.withOpacity(0.25),
                    tierStyle.accentColor.withOpacity(0.08),
                  ]),
                  border: Border.all(
                    color: tierStyle.accentColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tierStyle.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tierStyle.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        '${widget.level.currentLevel}',
                        style: TextStyle(
                          color: tierStyle.accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // XP progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      XPCounter(
                        currentXp: widget.level.currentXp,
                        nextThreshold: widget.level.nextThreshold,
                        textStyle: TextStyle(
                          color: widget.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.level.progressPct}%',
                        style: TextStyle(
                          color: tierStyle.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Animated progress bar
                  AnimatedProgressBar(
                    progress: widget.level.progressFraction,
                    fillColor: tierStyle.accentColor,
                    backgroundColor: Colors.white.withOpacity(0.08),
                  ),
                  const SizedBox(height: 5),

                  // Footer stats
                  Text(
                    'Total XP: ${_formatNumber(widget.level.totalXp)} · '
                    'Level ${widget.level.currentLevel}/${widget.level.maxLevel}',
                    style: TextStyle(
                      color: widget.textColor.withOpacity(0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}