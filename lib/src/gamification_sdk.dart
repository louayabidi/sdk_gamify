import 'package:shared_preferences/shared_preferences.dart';
import 'exceptions.dart';
import 'http_client.dart';
import 'models.dart';

export 'exceptions.dart';
export 'models.dart';

typedef OnRewardReceived = void Function(List<GamificationReward> rewards);

class GamificationSDK {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static GamificationSDK? _instance;

  static GamificationSDK get instance {
    if (_instance == null) throw const SdkNotInitializedException();
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  // ── Internal state ────────────────────────────────────────────────────────
  final String _apiKey;
  final String _baseUrl;
  final GamificationHttpClient _http;
  OnRewardReceived? _onReward;
  String? _currentUserId;

  static const String _kUserId = 'gamification_sdk_user_id';

  // ── Private constructor ───────────────────────────────────────────────────
  GamificationSDK._({
    required String apiKey,
    required String baseUrl,
    required GamificationHttpClient http,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _http = http;

  // ── INITIALIZE ────────────────────────────────────────────────────────────
  static Future<GamificationSDK> initialize({
    required String apiKey,
    required String baseUrl,
    OnRewardReceived? onReward,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    assert(apiKey.isNotEmpty, 'apiKey ne peut pas être vide');
    assert(baseUrl.isNotEmpty, 'baseUrl ne peut pas être vide');

    _instance?._http.dispose();

    final http = GamificationHttpClient(
      baseUrl: baseUrl,
      apiKey: apiKey,
      timeout: timeout,
    );

    final sdk = GamificationSDK._(
      apiKey: apiKey,
      baseUrl: baseUrl,
      http: http,
    );

    sdk._onReward = onReward;
    await sdk._restoreUserId();
    _instance = sdk;
    return sdk;
  }

  // ── WIDGET CONFIG ─────────────────────────────────────────────────────────
  Future<WidgetConfig> getWidgetConfig(String publishableKey) async {
  try {
    final response = await _http.get('/api/widgets/public/$publishableKey');
                                              
    return WidgetConfig.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    throw GamificationApiException(
      statusCode: 0,
      message: 'Failed to load widget config: $e',
    );
  }
}

  // ── IDENTIFY ──────────────────────────────────────────────────────────────
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    assert(userId.isNotEmpty, 'userId ne peut pas être vide');
    _currentUserId = userId;
    await _persistUserId(userId);
  }

  // ── TRACK ─────────────────────────────────────────────────────────────────
  Future<List<GamificationReward>> track(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    if (_currentUserId == null) throw const NoUserIdentifiedException();

    final response = await _http.post('/api/events/track', {
      'userId': _currentUserId!,
      'eventName': eventName,
      'data': data ?? <String, dynamic>{},
    });

    final rawList = response as List<dynamic>? ?? [];
    final rewards = rawList
        .map((item) => GamificationReward.fromJson(item as Map<String, dynamic>))
        .toList();

    if (rewards.isNotEmpty) {
      _onReward?.call(rewards);
    }

    return rewards;
  }

  // ── GET USER PROFILE ──────────────────────────────────────────────────────
  Future<GamificationProfile> getUserProfile({String? userId}) async {
    final target = userId ?? _currentUserId;
    if (target == null) throw const NoUserIdentifiedException();

    final response = await _http.get('/api/users/$target');
    return GamificationProfile.fromJson(response as Map<String, dynamic>);
  }

  // ── GET POINTS ────────────────────────────────────────────────────────────
  Future<PointsBalance> getPoints() async {
    if (_currentUserId == null) throw const NoUserIdentifiedException();

    final response = await _http.get('/api/users/$_currentUserId/points');
    return PointsBalance.fromJson(response as Map<String, dynamic>);
  }

  // ── GETTERS ───────────────────────────────────────────────────────────────
  String? get currentUserId => _currentUserId;
  bool get hasUser => _currentUserId != null;
  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;

  // ── RESET ─────────────────────────────────────────────────────────────────
  Future<void> reset() async {
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
  }

  // ── DISPOSE ───────────────────────────────────────────────────────────────
  void dispose() {
    _http.dispose();
    _instance = null;
  }

  // ── INTERNAL ──────────────────────────────────────────────────────────────
  Future<void> _persistUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
  }

  Future<void> _restoreUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString(_kUserId);
  }

} 