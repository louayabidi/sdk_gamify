// lib/src/gamif_reward_notifier.dart
//
// Global singleton that broadcasts rewards to any active listener,
// regardless of which widget is currently mounted.
// The SDK pushes here; GamifCelebrationOverlay listens here.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'models.dart';

class GamifRewardNotifier {
  GamifRewardNotifier._();

  static final StreamController<GamificationReward> _ctrl =
      StreamController<GamificationReward>.broadcast();

  /// Push a reward to all active listeners.
  /// Safe to call from anywhere — SDK callbacks, background isolates, etc.
  static void notify(GamificationReward reward) {
    if (!_ctrl.isClosed) _ctrl.add(reward);
  }

  /// Subscribe to incoming rewards (badge, points, …).
  static Stream<GamificationReward> get stream => _ctrl.stream;
}