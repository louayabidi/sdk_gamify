// lib/src/models.dart
// Added: UserStreakData, UserLevelData, StreakReward, LevelReward

// ── GamificationReward ────────────────────────────────────────────────────────
class GamificationReward {
  final String  type;
  final dynamic data;
  final String  message;

  const GamificationReward({
    required this.type,
    required this.data,
    required this.message,
  });

  factory GamificationReward.fromJson(Map<String, dynamic> json) {
    return GamificationReward(
      type   : json['type']    as String? ?? 'UNKNOWN',
      data   : json['data'],
      message: json['message'] as String? ?? '',
    );
  }

  bool get isBadge       => type == 'BADGE';
  bool get isPoints      => type == 'POINTS';
  bool get isStreakUpdate => type == 'STREAK_UPDATE';
  bool get isLevelUp     => type == 'LEVEL_UP';
  bool get isLevelUpdate => type == 'LEVEL_UPDATE';
  bool get isFreezeToken => type == 'FREEZE_TOKEN';

  int? get pointsValue {
    if (!isPoints) return null;
    if (data is int) return data as int;
    if (data is String) return int.tryParse(data as String);
    if (data is Map) {
      final amt = (data as Map)['amount'];
      if (amt is int) return amt;
      if (amt is String) return int.tryParse(amt);
    }
    return null;
  }

  String? get badgeName {
    if (!isBadge) return null;
    if (data is Map) return (data as Map)['name'] as String?;
    return null;
  }

  String? get badgeImageUrl {
    if (!isBadge) return null;
    if (data is Map) return (data as Map)['imageUrl'] as String?;
    return null;
  }

  /// Streak data from STREAK_UPDATE / STREAK_FREEZE_USED rewards
  UserStreakData? get streakData {
    if (!isStreakUpdate) return null;
    if (data is Map) return UserStreakData.fromMap(data as Map<String, dynamic>);
    return null;
  }

  /// Level data from LEVEL_UP / LEVEL_UPDATE rewards
  UserLevelData? get levelData {
    if (!isLevelUp && !isLevelUpdate) return null;
    if (data is Map) return UserLevelData.fromMap(data as Map<String, dynamic>);
    return null;
  }
}

// ── UserStreakData — embedded in STREAK_UPDATE rewards ────────────────────────
class UserStreakData {
  final int    streakConfigId;
  final String streakName;
  final int    currentStreak;
  final int    longestStreak;
  final int    freezeTokens;
  final double multiplier;
  final bool   streakBroken;

  const UserStreakData({
    required this.streakConfigId,
    required this.streakName,
    required this.currentStreak,
    required this.longestStreak,
    required this.freezeTokens,
    required this.multiplier,
    required this.streakBroken,
  });

  factory UserStreakData.fromMap(Map<String, dynamic> m) => UserStreakData(
    streakConfigId: (m['streakConfigId'] as num?)?.toInt() ?? 0,
    streakName    : m['streakName']   as String? ?? '',
    currentStreak : (m['currentStreak']  as num?)?.toInt() ?? 0,
    longestStreak : (m['longestStreak']  as num?)?.toInt() ?? 0,
    freezeTokens  : (m['freezeTokens']  as num?)?.toInt() ?? 0,
    multiplier    : (m['multiplier']    as num?)?.toDouble() ?? 1.0,
    streakBroken  : m['streakBroken']   as bool? ?? false,
  );
}

// ── UserLevelData — embedded in LEVEL_UP / LEVEL_UPDATE rewards ───────────────
class UserLevelData {
  final int    levelConfigId;
  final String levelName;
  final int    currentLevel;
  final int    currentXp;
  final int    nextThreshold;
  final int    totalXp;
  final String title;
  final int    progressPct;

  const UserLevelData({
    required this.levelConfigId,
    required this.levelName,
    required this.currentLevel,
    required this.currentXp,
    required this.nextThreshold,
    required this.totalXp,
    required this.title,
    required this.progressPct,
  });

  factory UserLevelData.fromMap(Map<String, dynamic> m) => UserLevelData(
    levelConfigId : (m['levelConfigId']  as num?)?.toInt() ?? 0,
    levelName     : m['levelName']       as String? ?? '',
    currentLevel  : (m['currentLevel']   as num?)?.toInt() ?? 1,
    currentXp     : (m['currentXp']      as num?)?.toInt() ?? 0,
    nextThreshold : (m['nextThreshold']  as num?)?.toInt() ?? 1000,
    totalXp       : (m['totalXp']        as num?)?.toInt() ?? 0,
    title         : m['title']           as String? ?? '',
    progressPct   : (m['progressPct']    as num?)?.toInt() ?? 0,
  );

  double get progressFraction =>
      nextThreshold > 0 ? (currentXp / nextThreshold).clamp(0.0, 1.0) : 0.0;
}

// ── Streak/Level API response models (for getStreaks / getLevels) ──────────────

class UserStreakInfo {
  final int    streakConfigId;
  final String streakName;
  final String windowType;
  final int    maxFreezeTokens;
  final int    currentStreak;
  final int    longestStreak;
  final int    freezeTokens;
  final String? lastActivityAt;

  const UserStreakInfo({
    required this.streakConfigId,
    required this.streakName,
    required this.windowType,
    required this.maxFreezeTokens,
    required this.currentStreak,
    required this.longestStreak,
    required this.freezeTokens,
    this.lastActivityAt,
  });

  factory UserStreakInfo.fromJson(Map<String, dynamic> j) => UserStreakInfo(
    streakConfigId : (j['streakConfigId'] as num?)?.toInt() ?? 0,
    streakName     : j['streakName']      as String? ?? '',
    windowType     : j['windowType']      as String? ?? 'CALENDAR_DAY',
    maxFreezeTokens: (j['maxFreezeTokens'] as num?)?.toInt() ?? 1,
    currentStreak  : (j['currentStreak']  as num?)?.toInt() ?? 0,
    longestStreak  : (j['longestStreak']  as num?)?.toInt() ?? 0,
    freezeTokens   : (j['freezeTokens']  as num?)?.toInt() ?? 0,
    lastActivityAt : j['lastActivityAt']  as String?,
  );
}

class UserLevelInfo {
  final int    levelConfigId;
  final String levelName;
  final int    currentLevel;
  final int    currentXp;
  final int    nextThreshold;
  final int    totalXp;
  final int    headStartPct;
  final int    maxLevel;
  final int    progressPct;
  final String? levelTitlesJson;

  const UserLevelInfo({
    required this.levelConfigId,
    required this.levelName,
    required this.currentLevel,
    required this.currentXp,
    required this.nextThreshold,
    required this.totalXp,
    required this.headStartPct,
    required this.maxLevel,
    required this.progressPct,
    this.levelTitlesJson,
  });

  factory UserLevelInfo.fromJson(Map<String, dynamic> j) => UserLevelInfo(
    levelConfigId  : (j['levelConfigId']  as num?)?.toInt() ?? 0,
    levelName      : j['levelName']       as String? ?? '',
    currentLevel   : (j['currentLevel']   as num?)?.toInt() ?? 1,
    currentXp      : (j['currentXp']      as num?)?.toInt() ?? 0,
    nextThreshold  : (j['nextThreshold']  as num?)?.toInt() ?? 1000,
    totalXp        : (j['totalXp']        as num?)?.toInt() ?? 0,
    headStartPct   : (j['headStartPct']   as num?)?.toInt() ?? 15,
    maxLevel       : (j['maxLevel']       as num?)?.toInt() ?? 100,
    progressPct    : (j['progressPct']    as num?)?.toInt() ?? 0,
    levelTitlesJson: j['levelTitlesJson'] as String?,
  );

  double get progressFraction =>
      nextThreshold > 0 ? (currentXp / nextThreshold).clamp(0.0, 1.0) : 0.0;
}

// ── WidgetConfig ──────────────────────────────────────────────────────────────
class WidgetConfig {
  final String  publishableKey;
  final String  displayMode;
  final String  contentMode;
  final String  backgroundColor;
  final String  textColor;
  final String  accentColor;
  final String  label;
  final bool    showLifetime;
  final bool    showLevel;
  final bool    animate;
  final int     borderRadius;
  final String? fontFamily;
  final bool    darkMode;
  final String  language;
  final String? layoutJson;

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
    this.layoutJson,
  });

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      publishableKey : json['publishableKey']  as String,
      displayMode    : json['displayMode']     as String,
      contentMode    : json['contentMode']     as String,
      backgroundColor: json['backgroundColor'] as String,
      textColor      : json['textColor']       as String,
      accentColor    : json['accentColor']     as String,
      label          : json['label']           as String,
      showLifetime   : json['showLifetime']    as bool?   ?? false,
      showLevel      : json['showLevel']       as bool?   ?? true,
      animate        : json['animate']         as bool?   ?? true,
      borderRadius   : json['borderRadius']    as int?    ?? 12,
      fontFamily     : json['fontFamily']      as String?,
      darkMode       : json['darkMode']        as bool?   ?? false,
      language       : json['language']        as String? ?? 'en',
      layoutJson     : json['layoutJson']      as String?,
    );
  }
}

// ── PointsBalance ─────────────────────────────────────────────────────────────
class PointsBalance {
  final String userId;
  final int    balance;
  final int    lifetimeEarned;

  const PointsBalance({
    required this.userId,
    required this.balance,
    required this.lifetimeEarned,
  });

  factory PointsBalance.fromJson(Map<String, dynamic> json) => PointsBalance(
    userId        : json['userId']         as String,
    balance       : json['balance']        as int,
    lifetimeEarned: json['lifetimeEarned'] as int,
  );
}

// ── UserBadge ─────────────────────────────────────────────────────────────────
class UserBadge {
  final int    badgeId;
  final String awardedAt;
  final String name;
  final String imageUrl;

  const UserBadge({
    required this.badgeId,
    required this.awardedAt,
    this.name     = '',
    this.imageUrl = '',
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badgeId  : json['badgeId']   as int?    ?? 0,
      awardedAt: json['awardedAt'] as String? ?? '',
      name     : json['name']      as String? ?? '',
      imageUrl : json['imageUrl']  as String? ?? '',
    );
  }
}

// ── GamificationProfile ───────────────────────────────────────────────────────
class GamificationProfile {
  final String          userId;
  final List<UserBadge> badges;
  final int             points;

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