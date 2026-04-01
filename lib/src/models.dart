class GamificationReward {
  final String type;
  final Map<String, dynamic> data;
  final String message;

  const GamificationReward({
    required this.type,
    required this.data,
    required this.message,
  });

  factory GamificationReward.fromJson(Map<String, dynamic> json) {
    return GamificationReward(
      type: json['type'] as String? ?? 'UNKNOWN',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      message: json['message'] as String? ?? '',
    );
  }

  bool get isBadge => type == 'BADGE';
  bool get isPoints => type == 'POINTS';

  @override
  String toString() => 'GamificationReward(type: $type, message: $message)';
}

// ✅ TOP-LEVEL — plus imbriqué dans GamificationReward
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