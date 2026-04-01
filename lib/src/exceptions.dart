class SdkNotInitializedException implements Exception {
  const SdkNotInitializedException();

  @override
  String toString() =>
      '[GamificationSDK] Not initialized. Call GamificationSDK.initialize() first.';
}

/// Erreur levée si on appelle track() ou getUserProfile() sans avoir fait identify().
class NoUserIdentifiedException implements Exception {
  const NoUserIdentifiedException();

  @override
  String toString() =>
      '[GamificationSDK] No user identified. Call identify(userId) first.';
}

/// Erreur HTTP retournée par le backend (ex: 401, 404, 500).
class GamificationApiException implements Exception {
  final int statusCode;
  final String message;

  const GamificationApiException({
    required this.statusCode,
    required this.message,
  });

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => '[GamificationSDK] API Error $statusCode: $message';
}

/// Erreur réseau (pas d'internet, timeout, backend éteint...).
class GamificationNetworkException implements Exception {
  final String message;
  final Object? cause;

  const GamificationNetworkException({required this.message, this.cause});

  @override
  String toString() => '[GamificationSDK] Network Error: $message';
}