// lib/src/widgets/gamif_celebration_overlay.dart
//
// Wrap your MaterialApp's `builder:` with this widget.
// It listens to the global GamifRewardNotifier stream and shows
// GamifBadgeCelebration on top of the ENTIRE navigation stack —
// completely independent of which screen is active or mounted.
//
// Usage in your app:
//
//   MaterialApp(
//     builder: (context, child) => GamifCelebrationOverlay(
//       primaryColor: Color(0xFF6366F1),   // your brand color
//       accentColor : Color(0xFF34D399),   // your accent color
//       child       : child!,
//     ),
//     home: YourHomeScreen(),
//   )
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../gamif_reward_notifier.dart';
import '../models.dart';
import 'gamif_badge_celebration.dart';

class GamifCelebrationOverlay extends StatefulWidget {
  final Widget child;
  final Color  primaryColor;
  final Color  accentColor;

  const GamifCelebrationOverlay({
    super.key,
    required this.child,
    this.primaryColor = const Color(0xFF6366F1),
    this.accentColor  = const Color(0xFF34D399),
  });

  @override
  State<GamifCelebrationOverlay> createState() =>
      _GamifCelebrationOverlayState();
}

class _GamifCelebrationOverlayState extends State<GamifCelebrationOverlay> {
  StreamSubscription<GamificationReward>? _sub;

  // Queue so we never drop a reward if two arrive close together
  final List<GamificationReward> _queue = [];
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _sub = GamifRewardNotifier.stream.listen(_onReward);
  }

  void _onReward(GamificationReward reward) {
    if (!reward.isBadge) return; // only badges get the full-screen treatment
    _queue.add(reward);
    _showNext();
  }

  void _showNext() {
    if (_showing || _queue.isEmpty || !mounted) return;
    _showing = true;
    setState(() {}); // rebuild to show the celebration
  }

  void _dismiss() {
    if (!mounted) return;
    _queue.removeAt(0);
    _showing = false;
    setState(() {});
    // Show the next queued reward (if any) after a short breath
    if (_queue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), _showNext);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The entire app lives here
        widget.child,

        // Celebration floats on top of everything, including the AppBar
        if (_showing && _queue.isNotEmpty)
          Positioned.fill(
            child: GamifBadgeCelebration(
              key         : ValueKey(_queue.first.hashCode),
              reward      : _queue.first,
              primaryColor: widget.primaryColor,
              accentColor : widget.accentColor,
              onDismiss   : _dismiss,
            ),
          ),
      ],
    );
  }
}