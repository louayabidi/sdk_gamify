class GamificationReward {
  final String type;
  final dynamic data;        // ← change from Map to dynamic
  final String message;

  const GamificationReward({
    required this.type,
    required this.data,
    required this.message,
  });

  factory GamificationReward.fromJson(Map<String, dynamic> json) {
    return GamificationReward(
      type: json['type'] as String? ?? 'UNKNOWN',
      data: json['data'],    // ← no cast, accept int or Map
      message: json['message'] as String? ?? '',
    );
  }

  bool get isBadge => type == 'BADGE';
  bool get isPoints => type == 'POINTS';

  // Helper to get points value safely
  int? get pointsValue => isPoints && data is int ? data as int : null;
}

// ── WidgetConfig — top-level, NOT nested ─────────────────────────────────────
class WidgetConfig {
  final String publishableKey;
  final String displayMode;
  final String contentMode;
  final String backgroundColor;
  final String textColor;
  final String accentColor;
  final String label;
  final bool showLifetime;
  final bool showLevel;
  final bool animate;
  final int borderRadius;
  final String? fontFamily;
  final bool darkMode;
  final String language;

  WidgetConfig({
    required this.publishableKey,
    required this.displayMode,
    required this.contentMode,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.label,
    required this.showLifetime,
    required this.showLevel,
    required this.animate,
    required this.borderRadius,
    this.fontFamily,
    required this.darkMode,
    required this.language,
  });

factory WidgetConfig.fromJson(Map<String, dynamic> json) {
  return WidgetConfig(
    publishableKey: json['publishableKey'] as String,
    displayMode: json['displayMode'] as String,
    contentMode: json['contentMode'] as String,
    backgroundColor: json['backgroundColor'] as String,
    textColor: json['textColor'] as String,
    accentColor: json['accentColor'] as String,
    label: json['label'] as String,
    showLifetime: json['showLifetime'] as bool? ?? false,
    showLevel: json['showLevel'] as bool? ?? true,
    animate: json['animate'] as bool? ?? true,
    borderRadius: json['borderRadius'] as int? ?? 12,
    fontFamily: json['fontFamily'] as String?,
    darkMode: json['darkMode'] as bool? ?? false,
    language: json['language'] as String? ?? 'en',
  );
}
}

// ── PointsBalance ─────────────────────────────────────────────────────────────
class PointsBalance {
  final String userId;
  final int balance;
  final int lifetimeEarned;

  const PointsBalance({
    required this.userId,
    required this.balance,
    required this.lifetimeEarned,
  });

  factory PointsBalance.fromJson(Map<String, dynamic> json) => PointsBalance(
        userId: json['userId'] as String,
        balance: json['balance'] as int,
        lifetimeEarned: json['lifetimeEarned'] as int,
      );
}

// ── UserBadge ─────────────────────────────────────────────────────────────────
class UserBadge {
  final int badgeId;
  final String awardedAt;

  const UserBadge({required this.badgeId, required this.awardedAt});

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badgeId: json['badgeId'] as int? ?? 0,
      awardedAt: json['awardedAt'] as String? ?? '',
    );
  }
}

// ── GamificationProfile ───────────────────────────────────────────────────────
class GamificationProfile {
  final String userId;
  final List<UserBadge> badges;
  final int points;

  const GamificationProfile({
    required this.userId,
    required this.badges,
    required this.points,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    final badgeList = (json['badges'] as List<dynamic>? ?? [])
        .map((b) => UserBadge.fromJson(b as Map<String, dynamic>))
        .toList();

    return GamificationProfile(
      userId: json['userId'] as String? ?? '',
      badges: badgeList,
      points: json['points'] as int? ?? 0,
    );
  }

  int get badgeCount => badges.length;

  @override
  String toString() =>
      'GamificationProfile(userId: $userId, badges: $badgeCount, points: $points)';
}