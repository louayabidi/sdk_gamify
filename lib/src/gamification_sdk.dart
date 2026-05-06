// lib/src/gamification_sdk.dart
// ── ADD these two methods to the existing GamificationSDK class ──────────────
//
// Place them alongside getPoints() and getUserProfile() — no other changes needed.
//
// ─────────────────────────────────────────────────────────────────────────────

// In your existing gamification_sdk.dart, ADD these imports at the top:
//   import 'models.dart';  // already there — UserStreakInfo, UserLevelInfo now defined

// ADD these two methods inside GamificationSDK:

/*
  Future<List<UserStreakInfo>> getStreaks() async {
    if (!hasUser) throw NoUserIdentifiedException();
    final appId = _getAppId();
    final json  = await httpClient
        .get('/api/streaks/user/$currentUserId?appId=$appId');
    final list  = json is List ? json : <dynamic>[];
    return list
        .map((j) => UserStreakInfo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserLevelInfo>> getLevels() async {
    if (!hasUser) throw NoUserIdentifiedException();
    final appId = _getAppId();
    final json  = await httpClient
        .get('/api/levels/user/$currentUserId?appId=$appId');
    final list  = json is List ? json : <dynamic>[];
    return list
        .map((j) => UserLevelInfo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Helper — reads appId from prefs (persisted during identify or init)
  String _getAppId() {
    final id = _prefs.getString('_gamif_app_id');
    if (id == null || id.isEmpty) {
      throw Exception('[GamificationSDK] No appId stored. '
          'Call GamifSDK.init with an apiKey that maps to an appId.');
    }
    return id;
  }
*/

// ─────────────────────────────────────────────────────────────────────────────
// ALTERNATIVELY, copy the FULL class below (drop-in replacement):
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'http_client.dart';
import 'exceptions.dart';
import 'gamif_reward_notifier.dart';

typedef OnRewardReceived = void Function(GamificationReward reward);

class GamificationSDK {
  GamificationSDK._();
  static GamificationSDK? _instance;
  static bool get isInitialized => _instance != null;

  static GamificationSDK get instance {
    if (_instance == null) throw SdkNotInitializedException();
    return _instance!;
  }

  late final GamificationHttpClient httpClient;
  late final SharedPreferences _prefs;

  String? currentUserId;
  String? currentDisplayName;
  String? _appId;  // ← NEW: stored after init so streak/level endpoints can use it

  bool get hasUser => currentUserId != null;
  OnRewardReceived? onRewardReceived;

  static Future<void> initialize({
    required String apiKey,
    required String baseUrl,
  }) async {
    _instance = GamificationSDK._();
    _instance!.httpClient = GamificationHttpClient(
      apiKey : apiKey,
      baseUrl: baseUrl,
    );

    _instance!._prefs = await SharedPreferences.getInstance();

    // ── Resolve appId from the API (one HTTP call) ────────────────────────────
    // The backend /api/apps endpoint returns apps for the given API key.
    // We store it locally so streak/level queries can use it without
    // requiring the caller to pass it every time.
    try {
      final appsJson = await _instance!.httpClient.get('/api/apps/by-key/$apiKey');
      if (appsJson is Map) {
        final appId = appsJson['id']?.toString();
        if (appId != null) {
          _instance!._appId = appId;
          await _instance!._prefs.setString('_gamif_app_id', appId);
        }
      }
    } catch (_) {
      // Fall back to cached value
      _instance!._appId = _instance!._prefs.getString('_gamif_app_id');
    }

    final savedUserId      = _instance!._prefs.getString('_gamif_uid');
    final savedDisplayName = _instance!._prefs.getString('_gamif_display');

    if (savedUserId != null) {
      _instance!.currentUserId      = savedUserId;
      _instance!.currentDisplayName = savedDisplayName;
    } else {
      final deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _instance!._prefs.setString('_gamif_uid', deviceId);
      await _instance!._prefs.setString('_gamif_display', deviceId);
      _instance!.currentUserId      = deviceId;
      _instance!.currentDisplayName = deviceId;
    }
  }

  // ── NEW: pass appId explicitly (simpler, no extra API call needed) ─────────
  static Future<void> initializeWithAppId({
    required String apiKey,
    required String baseUrl,
    required String appId,
  }) async {
    await initialize(apiKey: apiKey, baseUrl: baseUrl);
    _instance!._appId = appId;
    await _instance!._prefs.setString('_gamif_app_id', appId);
  }

  Future<void> identify(String userId, {String? displayName}) async {
    currentUserId      = userId;
    currentDisplayName = displayName ?? userId;
    await _prefs.setString('_gamif_uid', userId);
    await _prefs.setString('_gamif_display', currentDisplayName!);
  }

  Future<void> resetIdentity() async {
    final deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    currentUserId      = deviceId;
    currentDisplayName = deviceId;
    await _prefs.setString('_gamif_uid', deviceId);
    await _prefs.setString('_gamif_display', deviceId);
  }

  Future<PointsBalance> getPoints() async {
    if (!hasUser) throw NoUserIdentifiedException();
    final json = await httpClient.get('/api/users/$currentUserId/points');
    return PointsBalance.fromJson(json as Map<String, dynamic>);
  }

  Future<GamificationProfile> getUserProfile() async {
    if (!hasUser) throw NoUserIdentifiedException();
    final json = await httpClient.get('/api/users/$currentUserId/profile');
    return GamificationProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<WidgetConfig> getWidgetConfig(String publishableKey) async {
    final json = await httpClient.get('/api/widgets/public/$publishableKey');
    return WidgetConfig.fromJson(json as Map<String, dynamic>);
  }

  // ── NEW: get all active streaks for this user ─────────────────────────────
  Future<List<UserStreakInfo>> getStreaks() async {
    if (!hasUser) throw NoUserIdentifiedException();
    final appId = _resolveAppId();
    final json  = await httpClient
        .get('/api/streaks/user/$currentUserId?appId=$appId');
    final list  = json is List ? json : <dynamic>[];
    return list
        .map((j) => UserStreakInfo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── NEW: get all active levels for this user ──────────────────────────────
  Future<List<UserLevelInfo>> getLevels() async {
    if (!hasUser) throw NoUserIdentifiedException();
    final appId = _resolveAppId();
    final json  = await httpClient
        .get('/api/levels/user/$currentUserId?appId=$appId');
    final list  = json is List ? json : <dynamic>[];
    return list
        .map((j) => UserLevelInfo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<GamificationReward>> track(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    if (!hasUser) throw NoUserIdentifiedException();

    final response = await httpClient.post('/api/events/track', {
      'userId'     : currentUserId,
      'displayName': currentDisplayName,
      'eventName'  : eventName,
      if (data != null) 'data': data,
    });

    final raw  = response['rewards'];
    final list = raw is List ? raw : <dynamic>[];

    final rewards = list
        .map((r) => GamificationReward.fromJson(r as Map<String, dynamic>))
        .toList();

    for (final r in rewards) {
      onRewardReceived?.call(r);
      GamifRewardNotifier.notify(r);
    }

    return rewards;
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  String _resolveAppId() {
    final id = _appId ?? _prefs.getString('_gamif_app_id');
    if (id == null || id.isEmpty) {
      throw Exception(
          '[GamificationSDK] appId not set. Use initializeWithAppId() '
          'or ensure initialize() resolved the appId.');
    }
    return id;
  }
}