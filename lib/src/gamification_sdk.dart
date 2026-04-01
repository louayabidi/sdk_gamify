// La classe principale du SDK. C'est ici que tout se connecte.

import 'package:shared_preferences/shared_preferences.dart';
import 'exceptions.dart';
import 'http_client.dart';
import 'models.dart';

export 'exceptions.dart';
export 'models.dart';

/// Callback déclenché quand des récompenses sont reçues.
typedef OnRewardReceived = void Function(List<GamificationReward> rewards);

class GamificationSDK {
  // ── Singleton : une seule instance dans toute l'app ──────────────────────
  static GamificationSDK? _instance;
//la creation de GamificationSDK c'est un sngleton privé il faut vérifier si la classe est déjà 
//initialisée avant de permettre l'accès à l'instance si elle n'exste pas on ecrit 
//si le if return null il faut créer un new instance sinon on retourne l'instance déjà créée

  static GamificationSDK get instance {
    if (_instance == null) throw const SdkNotInitializedException();
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  // ── État interne ─────────────────────────────────────────────────────────
  final String _apiKey;
  final String _baseUrl;
  final GamificationHttpClient _http;
  OnRewardReceived? _onReward;
  String? _currentUserId;

  //_instance : ~5 KB (une seule fois)
  //_currentUserId : 10-50 bytes
  ///Callbacks : ~1 KB


  static const String _kUserId = 'gamification_sdk_user_id';
// j'ajout de ._ au Le constructeur GamificationSDK pour dire qu'il est privé à la bibliothèque pour qu’on ne puisse pas créer d’instance directement de l’extérieur
  GamificationSDK._({
    required String apiKey,
    required String baseUrl,
    required GamificationHttpClient http,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _http = http;

  // ── INITIALIZE ───────────────────────────────────────────────────────────
  /// Initialise le SDK. À appeler une seule fois au démarrage de l'app.
  ///
  /// [apiKey]   → clé API générée dans le dashboard Spring Boot
  /// [baseUrl]  → URL de votre backend
  /// [onReward] → callback optionnel appelé à chaque récompense reçue
  static Future<GamificationSDK> initialize({
    required String apiKey,
    required String baseUrl,
    OnRewardReceived? onReward,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    assert(apiKey.isNotEmpty, 'apiKey ne peut pas être vide');
    assert(baseUrl.isNotEmpty, 'baseUrl ne peut pas être vide');

 // Étape 1: Nettoie l'ancienne instance si elle existe
    _instance?._http.dispose();

// Étape 2: Crée un nouvel HttpClient avec votre clé API
    final http = GamificationHttpClient(
      baseUrl: baseUrl,
      apiKey: apiKey,
      timeout: timeout,
    );

    // Étape 3: Crée l'instance Singleton du SDK
    final sdk = GamificationSDK._(
      apiKey: apiKey,
      baseUrl: baseUrl,
      http: http,
    );

     // Étape 4: Attache le callback
    sdk._onReward = onReward;
    
    // Étape 5: CRITIQUE - Restaure l'utilisateur précédent si disponible
    await sdk._restoreUserId();

// Étape 6: Assigne l'instance globale
    _instance = sdk;
    return sdk;
  }

  // ── IDENTIFY ─────────────────────────────────────────────────────────────
  /// Identifie l'utilisateur courant de l'app externe. Le SDK mémorise cet identifiant (localement, dans l’app) pour l’utiliser dans tous les appels suivants.
  /// L'userId est sauvegardé localement (survit aux redémarrages de l'app).
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    
    // 1. Valide que userId n'est pas vide
    assert(userId.isNotEmpty, 'userId ne peut pas être vide');

     // 2. Sauvegarde en mémoire RAM (pour accès rapide cette session)
    _currentUserId = userId;

      // 3. Sauvegarde en SharedPreferences (pour survie aux redémarrages)
    await _persistUserId(userId);
  }

  // ── TRACK ────────────────────────────────────────────────────────────────
  /// Envoie un événement au backend et retourne les récompenses obtenues.
  ///
  /// Le backend compare l'événement aux règles configurées dans le dashboard.
  /// Si une règle correspond → des récompenses (badges/points) sont retournées.
  ///
  
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

  // ── GET USER PROFILE ─────────────────────────────────────────────────────
  /// Récupère le profil d'un utilisateur (badges + points).
  Future<GamificationProfile> getUserProfile({String? userId}) async {
    final target = userId ?? _currentUserId;
    if (target == null) throw const NoUserIdentifiedException();

    final response = await _http.get('/api/users/$target');
    return GamificationProfile.fromJson(response as Map<String, dynamic>);
  }

  // ── GETTERS ──────────────────────────────────────────────────────────────
  String? get currentUserId => _currentUserId;
  bool get hasUser => _currentUserId != null;
  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;

  // ── RESET ────────────────────────────────────────────────────────────────
  /// Déconnecte l'utilisateur (à appeler au logout).
  Future<void> reset() async {
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
  }

  // ── INTERNAL ─────────────────────────────────────────────────────────────
  Future<void> _persistUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
  }

  Future<void> _restoreUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString(_kUserId);
  }

  void dispose() {
    _http.dispose();
    _instance = null;
  }


//pour récupérer le solde de points de l'utilisateur courant, on vérifie d'abord que l'utilisateur est identifié, puis on fait une requête GET à l'endpoint approprié et on parse la réponse en un objet PointsBalance. 
Future<PointsBalance> getPoints() async {
  if (_currentUserId == null) throw const NoUserIdentifiedException();

  final response = await _http.get(
    '/api/users/$_currentUserId/points',
  );

  return PointsBalance.fromJson(response as Map<String, dynamic>);
}


}