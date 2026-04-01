import 'gamification_sdk.dart';
import 'widgets/gamif_points_widget.dart';


class GamifTracker {
  static Future<void> track(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    if (!GamificationSDK.isInitialized) {
      print('[GamifTracker] ⚠️ SDK non initialisé');
      return;
    }
    try {
      if (!GamificationSDK.instance.hasUser) {
        final anonymousId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
        await GamificationSDK.instance.identify(anonymousId);
      }

      final rewards = await GamificationSDK.instance.track(eventName, data: data);
      print('[GamifTracker] ✅ "$eventName" envoyé');

      //  Si des points ont été gagnés → refresh immédiat du widget
      if (rewards.any((r) => r.isPoints)) {
        notifyPointsUpdated();
        print('[GamifTracker] 🔄 Points mis à jour');
      }

    } catch (e) {
      print('[GamifTracker] ❌ Erreur sur "$eventName": $e');
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
      apiKey: apiKey,
      baseUrl: baseUrl,
      onReward: onReward, //  brancher le callback
    );
    print('[GamifSDK] ✅ SDK initialisé — baseUrl: $baseUrl');
  }
}