// lib/src/widgets/gamif_streak_level_widget.dart
//
// Standalone widgets for streaks and levels.
// Used by GamifPage sections and can be embedded independently.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../gamification_sdk.dart';
import '../models.dart';
import 'gamif_points_widget.dart' show gamifRefreshController;

// ═════════════════════════════════════════════════════════════════════════════
// Streak Section Widget
// ═════════════════════════════════════════════════════════════════════════════

class GamifStreakSection extends StatefulWidget {
  final String  title;
  final Color   cardColor;
  final Color   textColor;
  final Color   accentColor;
  final double  radius;

  const GamifStreakSection({
    super.key,
    required this.title,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.radius,
  });

  @override
  State<GamifStreakSection> createState() => _GamifStreakSectionState();
}

class _GamifStreakSectionState extends State<GamifStreakSection> {
  List<UserStreakInfo> _streaks = [];
  bool _loading = true;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _fetchStreaks();
    _sub = gamifRefreshController.stream.listen((_) => _fetchStreaks());
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _fetchStreaks() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final streaks = await GamificationSDK.instance.getStreaks();
      if (mounted) setState(() { _streaks = streaks; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(widget.title,
                style: TextStyle(color: widget.textColor,
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 14),

          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_streaks.isEmpty)
            Text('No active streaks yet — start one!',
                style: TextStyle(color: widget.textColor.withOpacity(0.35),
                    fontSize: 12))
          else
            ..._streaks.map((s) => _StreakCard(
              streak: s,
              textColor: widget.textColor,
              accentColor: widget.accentColor,
              cardColor: widget.cardColor,
            )),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final UserStreakInfo streak;
  final Color textColor, accentColor, cardColor;

  const _StreakCard({
    required this.streak,
    required this.textColor,
    required this.accentColor,
    required this.cardColor,
  });

  static const Color _fireColor = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _fireColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fireColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            Expanded(
              child: Text(streak.streakName,
                  style: TextStyle(color: textColor,
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            // Freeze tokens
            if (streak.freezeTokens > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF87CEEB).withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('❄️', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 3),
                  Text('${streak.freezeTokens}',
                      style: const TextStyle(color: Color(0xFF87CEEB),
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
          const SizedBox(height: 10),

          // Main streak display
          Row(children: [
            // Flame + count
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _fireColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                streak.currentStreak > 0
                    ? _flameForStreak(streak.currentStreak) : '💤',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${streak.currentStreak}',
                    style: TextStyle(color: _fireColor, fontSize: 32,
                        fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(width: 6),
                Text('days',
                    style: TextStyle(color: textColor.withOpacity(0.5),
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              Text('Best: ${streak.longestStreak} days',
                  style: TextStyle(color: textColor.withOpacity(0.4),
                      fontSize: 11)),
            ]),
            const Spacer(),
            // Window type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                streak.windowType == 'CALENDAR_DAY' ? '📅 Daily' : '⏱ 24h',
                style: TextStyle(color: textColor.withOpacity(0.4),
                    fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  String _flameForStreak(int days) {
    if (days >= 30) return '🌟';
    if (days >= 14) return '🔥';
    if (days >= 7)  return '🔥';
    if (days >= 3)  return '✨';
    return '⚡';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Level Section Widget
// ═════════════════════════════════════════════════════════════════════════════

class GamifLevelSection extends StatefulWidget {
  final String title;
  final Color  cardColor;
  final Color  textColor;
  final Color  accentColor;
  final double radius;

  const GamifLevelSection({
    super.key,
    required this.title,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.radius,
  });

  @override
  State<GamifLevelSection> createState() => _GamifLevelSectionState();
}

class _GamifLevelSectionState extends State<GamifLevelSection>
    with SingleTickerProviderStateMixin {

  List<UserLevelInfo> _levels = [];
  bool _loading = true;
  StreamSubscription<void>? _sub;

  late AnimationController _progressCtrl;
  late Animation<double>   _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut);
    _fetchLevels();
    _sub = gamifRefreshController.stream.listen((_) => _fetchLevels());
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLevels() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final levels = await GamificationSDK.instance.getLevels();
      if (mounted) {
        setState(() { _levels = levels; _loading = false; });
        _progressCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎖️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(widget.title,
                style: TextStyle(color: widget.textColor,
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 14),

          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_levels.isEmpty)
            Text('No level system configured for this app.',
                style: TextStyle(color: widget.textColor.withOpacity(0.35),
                    fontSize: 12))
          else
            ..._levels.map((l) => _LevelCard(
              level: l,
              textColor: widget.textColor,
              accentColor: widget.accentColor,
              progressAnim: _progressAnim,
            )),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserLevelInfo  level;
  final Color          textColor, accentColor;
  final Animation<double> progressAnim;

  const _LevelCard({
    required this.level,
    required this.textColor,
    required this.accentColor,
    required this.progressAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Level name + title
        Row(children: [
          Expanded(child: Text(level.levelName,
              style: TextStyle(color: textColor,
                  fontSize: 13, fontWeight: FontWeight.w700))),
          if (level.title.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Text(level.title,
                  style: TextStyle(color: accentColor,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 12),

        // Level number display
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                accentColor.withOpacity(0.25),
                accentColor.withOpacity(0.08),
              ]),
              border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
            ),
            child: Center(
              child: Text('${level.currentLevel}',
                  style: TextStyle(color: accentColor, fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // XP label
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${level.currentXp} / ${level.nextThreshold} XP',
                    style: TextStyle(color: textColor, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text('${level.progressPct}%',
                    style: TextStyle(color: accentColor,
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),

              // Animated progress bar
              AnimatedBuilder(
                animation: progressAnim,
                builder: (_, __) {
                  final animatedPct = level.progressFraction * progressAnim.value;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(children: [
                      Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: animatedPct.clamp(0.0, 1.0),
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              accentColor,
                              Color.lerp(accentColor, Colors.white, 0.3)!,
                            ]),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  );
                },
              ),
              const SizedBox(height: 5),
              Text('Total XP: ${_fmt(level.totalXp)} · Level ${level.currentLevel}/${level.maxLevel}',
                  style: TextStyle(color: textColor.withOpacity(0.3),
                      fontSize: 10)),
            ]),
          ),
        ]),
      ]),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}