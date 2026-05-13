// lib/src/widgets/gamif_premium_streak_section.dart
// Enhanced Streak Section with Premium Widgets

import 'package:flutter/material.dart';
import '../gamification_sdk.dart';
import '../models.dart';
import 'gamif_points_widget.dart' show gamifRefreshController;
import 'gamif_premium_streak_widget.dart';
import 'dart:async';

/// Premium Streak Section with particle effects, pulsing, and tier-based theming
class GamifPremiumStreakSection extends StatefulWidget {
  final String title;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final double radius;

  const GamifPremiumStreakSection({
    super.key,
    required this.title,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.radius,
  });

  @override
  State<GamifPremiumStreakSection> createState() =>
      _GamifPremiumStreakSectionState();
}

class _GamifPremiumStreakSectionState extends State<GamifPremiumStreakSection> {
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
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
            Text(
              widget.title,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_streaks.isEmpty)
            Text(
              'No active streaks yet — start one!',
              style: TextStyle(
                color: widget.textColor.withOpacity(0.35),
                fontSize: 12,
              ),
            )
          else
            ..._streaks.map((s) => PremiumStreakCard(
              streak: s,
              textColor: widget.textColor,
              accentColor: widget.accentColor,
              cardColor: widget.cardColor,
              onStreakComplete: () {
                // Optional callback for additional actions
              },
            )),
        ],
      ),
    );
  }
}