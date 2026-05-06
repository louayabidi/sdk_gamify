// lib/src/gamif_tracker.dart
import 'gamification_sdk.dart';
import 'widgets/gamif_points_widget.dart';
import 'gamif_reward_notifier.dart'; // ← NEW
import 'models.dart';

class GamifTracker {
  /// Track an event.
  ///
  /// Badge rewards are automatically broadcast to [GamifRewardNotifier]
  /// inside [GamificationSDK.track], so the app-level
  /// [GamifCelebrationOverlay] will show the animation without any
  /// additional wiring here.
  static Future<void> track(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    if (!GamificationSDK.isInitialized) {
      print('[GamifTracker] ⚠️ SDK not initialized');
      return;
    }
    try {
      final rewards = await GamificationSDK.instance
          .track(eventName, data: data);

      print('[GamifTracker] ✅ "$eventName" sent — '
          '${rewards.length} reward(s)');

      // Refresh the points widget if any points were awarded
      if (rewards.any((r) => r.isPoints)) {
        notifyPointsUpdated();
        print('[GamifTracker] 🔄 Points widget refreshed');
      }

      // Badge rewards are already pushed to GamifRewardNotifier by the SDK.
      // GamifCelebrationOverlay (placed in MaterialApp builder) will catch them.
    } catch (e) {
      print('[GamifTracker] ❌ Error on "$eventName": $e');
    }
  }
}

class GamifSDK {
  static Future<void> init({
    required String apiKey,
    String baseUrl = 'http://localhost:8081',
    void Function(List<GamificationReward> rewards)? onReward,
  }) async {
    await GamificationSDK.initialize(
      apiKey : apiKey,
      baseUrl: baseUrl,
    );
    if (onReward != null) {
      GamificationSDK.instance.onRewardReceived = (reward) {
        onReward([reward]);
      };
    }
    print('[GamifSDK] ✅ Initialized — baseUrl: $baseUrl');
  }
}