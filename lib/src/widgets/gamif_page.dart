// lib/src/widgets/gamif_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../gamification_sdk.dart';
import '../models.dart';
import 'gamif_points_widget.dart' show gamifRefreshController;
import 'gamif_badge_celebration.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class GamifPageConfig {
  final String publishableKey;
  final String backgroundColor;
  final String primaryColor;
  final String accentColor;
  final String textColor;
  final String cardColor;
  final int borderRadius;
  final bool animate;
  final bool showLockedBadges;
  final int badgeColumns;
  final int leaderboardSize;
  final String leaderboardSortBy;
  final List<_Section> sections;

  const GamifPageConfig({
    required this.publishableKey,
    required this.backgroundColor,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.cardColor,
    required this.borderRadius,
    required this.animate,
    required this.showLockedBadges,
    required this.badgeColumns,
    required this.leaderboardSize,
    required this.leaderboardSortBy,
    required this.sections,
  });

  factory GamifPageConfig.fromJson(Map<String, dynamic> j) {
    List<_Section> sections = [];
    if (j['sectionsJson'] != null) {
      try {
        final raw = jsonDecode(j['sectionsJson'] as String) as List;
        sections = raw
            .map((s) => _Section.fromJson(s as Map<String, dynamic>))
            .where((s) => s.enabled)
            .toList();
      } catch (_) {}
    }
    return GamifPageConfig(
      publishableKey   : j['publishableKey']    as String? ?? '',
      backgroundColor  : j['backgroundColor']   as String? ?? '#0F0F1A',
      primaryColor     : j['primaryColor']      as String? ?? '#6366F1',
      accentColor      : j['accentColor']       as String? ?? '#34D399',
      textColor        : j['textColor']         as String? ?? '#FFFFFF',
      cardColor        : j['cardColor']         as String? ?? '#1A1A2E',
      borderRadius     : j['borderRadius']      as int?    ?? 16,
      animate          : j['animate']           as bool?   ?? true,
      showLockedBadges : j['showLockedBadges']  as bool?   ?? true,
      badgeColumns     : j['badgeColumns']      as int?    ?? 3,
      leaderboardSize  : j['leaderboardSize']   as int?    ?? 10,
      leaderboardSortBy: j['leaderboardSortBy'] as String? ?? 'points',
      sections         : sections,
    );
  }
}

class _Section {
  final String type;
  final bool enabled;
  final String title;
  final Map<String, dynamic> config;

  const _Section({
    required this.type,
    required this.enabled,
    required this.title,
    required this.config,
  });

  factory _Section.fromJson(Map<String, dynamic> j) => _Section(
        type   : j['type']    as String? ?? '',
        enabled: j['enabled'] as bool?   ?? true,
        title  : j['title']   as String? ?? '',
        config : j['config']  as Map<String, dynamic>? ?? {},
      );
}

class _LeaderboardEntry {
  final int rank;
  final String userId;
  final int lifetimePoints;
  final int totalEvents;
  final int activeDays;
  final String? lastEventAt;

  const _LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.lifetimePoints,
    required this.totalEvents,
    required this.activeDays,
    this.lastEventAt,
  });

  factory _LeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      _LeaderboardEntry(
        rank          : (j['rank']            as num?)?.toInt() ?? 0,
        userId        : j['userId']           as String? ?? '',
        lifetimePoints: (j['lifetimePoints']  as num?)?.toInt() ?? 0,
        totalEvents   : (j['totalEvents']     as num?)?.toInt() ?? 0,
        activeDays    : (j['activeDaysCount'] as num?)?.toInt() ?? 0,
        lastEventAt   : j['lastEventAt']      as String?,
      );
}

class _LeaderboardData {
  final List<_LeaderboardEntry> top3;
  final List<_LeaderboardEntry> topN;
  final _LeaderboardEntry? userRank;
  final int totalUsers;

  const _LeaderboardData({
    required this.top3,
    required this.topN,
    required this.userRank,
    required this.totalUsers,
  });

  factory _LeaderboardData.fromJson(Map<String, dynamic> j) {
    List<_LeaderboardEntry> parse(dynamic list) =>
        (list as List<dynamic>? ?? [])
            .map((e) => _LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();

    return _LeaderboardData(
      top3      : parse(j['top3']),
      topN      : parse(j['topN']),
      userRank  : j['userRank'] != null
          ? _LeaderboardEntry.fromJson(j['userRank'] as Map<String, dynamic>)
          : null,
      totalUsers: (j['totalUsers'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GamifPage
// ─────────────────────────────────────────────────────────────────────────────

class GamifPage extends StatefulWidget {
  final String apiKey;
  const GamifPage({super.key, required this.apiKey});

  @override
  State<GamifPage> createState() => _GamifPageState();
}

class _GamifPageState extends State<GamifPage> with TickerProviderStateMixin {

  GamifPageConfig?     _config;
  PointsBalance?       _points;
  GamificationProfile? _profile;
  _LeaderboardData?    _leaderboard;
  bool                 _loading = true;
  StreamSubscription<void>? _refreshSub;

  late AnimationController _counterCtrl;
  int _displayedPoints = 0;
  int _targetPoints    = 0;

  GamificationReward? _unlockedBadge;

  @override
  void initState() {
    super.initState();

    _counterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _counterCtrl.addListener(() {
      final v = (_displayedPoints +
              (_targetPoints - _displayedPoints) *
                  Curves.easeOutCubic.transform(_counterCtrl.value))
          .round();
      if (mounted) setState(() => _displayedPoints = v);
    });

    _loadAll();
    _refreshSub = gamifRefreshController.stream.listen((_) => _loadLiveData());

    if (GamificationSDK.isInitialized) {
      final prev = GamificationSDK.instance.onRewardReceived;
      GamificationSDK.instance.onRewardReceived = (reward) {
        prev?.call(reward);
        if (reward.isBadge && mounted) _showBadgeCelebration(reward);
      };
    }
  }

  @override
  void dispose() {
    _counterCtrl.dispose();
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadConfig();
    await _loadLiveData();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadConfig() async {
    try {
      final json = await GamificationSDK.instance.httpClient
          .get('/api/gamif-page/public/${widget.apiKey}');
      if (mounted) setState(() => _config = GamifPageConfig.fromJson(json));
    } catch (e) {
      debugPrint('[GamifPage] config load error: $e');
    }
  }

  Future<void> _loadLiveData() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) return;
    final userId = GamificationSDK.instance.currentUserId ?? '';
    try {
      final results = await Future.wait<dynamic>([
        GamificationSDK.instance.getPoints(),
        GamificationSDK.instance.getUserProfile(),
        GamificationSDK.instance.httpClient.get(
            '/api/gamif-page/public/${widget.apiKey}/leaderboard?userId=$userId'),
      ]);
      if (!mounted) return;
      final pts = (results[0] as PointsBalance).balance;
      _targetPoints = pts;
      _counterCtrl.forward(from: 0);
      setState(() {
        _points      = results[0] as PointsBalance;
        _profile     = results[1] as GamificationProfile;
        _leaderboard = _LeaderboardData.fromJson(results[2] as Map<String, dynamic>);
      });
    } catch (e) {
      debugPrint('[GamifPage] live data error: $e');
    }
  }

  void _showBadgeCelebration(GamificationReward reward) {
    if (mounted) setState(() => _unlockedBadge = reward);
  }

  void _dismissCelebration() {
    if (mounted) setState(() => _unlockedBadge = null);
  }

  @override
  Widget build(BuildContext context) {
    final cfg     = _config;
    final bg      = cfg != null ? _hex(cfg.backgroundColor) : const Color(0xFF0F0F1A);
    final primary = cfg != null ? _hex(cfg.primaryColor)    : const Color(0xFF6366F1);
    final accent  = cfg != null ? _hex(cfg.accentColor)     : const Color(0xFF34D399);
    final text    = cfg != null ? _hex(cfg.textColor)       : Colors.white;
    final card    = cfg != null ? _hex(cfg.cardColor)       : const Color(0xFF1A1A2E);

    return SizedBox.expand(
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: card,
          foregroundColor: text,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 18),
                onPressed: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              ),
              Text(
                'My Rewards',
                style: TextStyle(
                    color: text, fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            if (_loading)
              Center(
                child: CircularProgressIndicator(color: primary),
              )
            else
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  if (cfg == null)
                    _errorCard(text)
                  else
                    ...cfg.sections.map((s) => _buildSection(s, cfg)),
                  const SizedBox(height: 32),
                ],
              ),

            // ── Premium badge-unlock celebration overlay ──────────────────
            if (_unlockedBadge != null)
              Positioned.fill(
                child: GamifBadgeCelebration(
                  reward      : _unlockedBadge!,
                  accentColor : accent,
                  primaryColor: primary,
                  onDismiss   : _dismissCelebration,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(_Section s, GamifPageConfig cfg) {
    final cardBg  = _hex(cfg.cardColor);
    final primary = _hex(cfg.primaryColor);
    final accent  = _hex(cfg.accentColor);
    final text    = _hex(cfg.textColor);
    final radius  = cfg.borderRadius.toDouble();

    switch (s.type) {
      case 'hero':
        return _HeroSection(
          section       : s,
          points        : _displayedPoints,
          lifetimeEarned: _points?.lifetimeEarned ?? 0,
          profile       : _profile,
          primaryColor  : primary,
          textColor     : text,
          animate       : cfg.animate,
        );
      case 'leaderboard':
        return _LeaderboardSection(
          section      : s,
          data         : _leaderboard,
          currentUserId: GamificationSDK.instance.currentUserId ?? '',
          primaryColor : primary,
          accentColor  : accent,
          cardColor    : cardBg,
          textColor    : text,
          radius       : radius,
        );
      case 'badges':
        return _BadgesSection(
          section    : s,
          profile    : _profile,
          cardColor  : cardBg,
          accentColor: accent,
          textColor  : text,
          radius     : radius,
          columns    : s.config['columns']    as int?  ?? cfg.badgeColumns,
          showLocked : s.config['showLocked'] as bool? ?? cfg.showLockedBadges,
        );
      case 'stats':
        return _StatsSection(
          section    : s,
          profile    : _profile,
          points     : _points,
          leaderboard: _leaderboard,
          cardColor  : cardBg,
          textColor  : text,
          accentColor: accent,
          radius     : radius,
        );
      case 'activity':
        return _ActivitySection(
          section    : s,
          cardColor  : cardBg,
          textColor  : text,
          accentColor: accent,
          radius     : radius,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _errorCard(Color text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Could not load page config',
            style: TextStyle(color: text)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final _Section section;
  final int points, lifetimeEarned;
  final GamificationProfile? profile;
  final Color primaryColor, textColor;
  final bool animate;

  const _HeroSection({
    required this.section,
    required this.points,
    required this.lifetimeEarned,
    required this.profile,
    required this.primaryColor,
    required this.textColor,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final showStreak   = section.config['showStreak']   as bool? ?? true;
    final showLifetime = section.config['showLifetime'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            Color.lerp(primaryColor, const Color(0xFF0A0A1A), 0.5)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 40,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('⭐', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fmt(points),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        Text(
                          section.title.toUpperCase(),
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (showStreak || showLifetime) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (showStreak)
                          _heroStat('🔥', '7', 'Day Streak', textColor),
                        if (showStreak && showLifetime)
                          Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withOpacity(0.1)),
                        if (showLifetime)
                          _heroStat(
                              '💎', _fmt(lifetimeEarned), 'Lifetime', textColor),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String icon, String val, String label, Color text) =>
      Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(val,
                  style: TextStyle(
                      color: text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: text.withOpacity(0.45),
                  fontSize: 9,
                  letterSpacing: 1)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: Leaderboard
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardSection extends StatelessWidget {
  final _Section section;
  final _LeaderboardData? data;
  final String currentUserId;
  final Color primaryColor, accentColor, cardColor, textColor;
  final double radius;

  const _LeaderboardSection({
    required this.section,
    required this.data,
    required this.currentUserId,
    required this.primaryColor,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final showPodium = section.config['showPodium'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  section.title,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                const Spacer(),
                if (data != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${data!.totalUsers} players',
                      style: TextStyle(
                          color: textColor.withOpacity(0.5), fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          if (data == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            if (showPodium && data!.top3.isNotEmpty)
              _Podium(
                  entries     : data!.top3,
                  primaryColor: primaryColor,
                  accentColor : accentColor,
                  textColor   : textColor),
            ...data!.topN.skip(3).map((e) => _RankRow(
                  entry        : e,
                  isCurrentUser: e.userId == currentUserId,
                  primaryColor : primaryColor,
                  textColor    : textColor,
                )),
            if (data!.userRank != null &&
                !data!.topN.any((e) => e.userId == currentUserId))
              _UserRankBanner(
                entry       : data!.userRank!,
                primaryColor: primaryColor,
                textColor   : textColor,
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<_LeaderboardEntry> entries;
  final Color primaryColor, accentColor, textColor;

  const _Podium({
    required this.entries,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = [
      if (entries.length > 1) entries[1],
      if (entries.isNotEmpty) entries[0],
      if (entries.length > 2) entries[2],
    ];
    final heights = [100.0, 124.0, 85.0];
    final medals  = ['🥈', '🥇', '🥉'];
    final colors  = [
      Colors.grey.shade400,
      const Color(0xFFF59E0B),
      const Color(0xFFB45309),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(ordered.length, (i) {
          final e = ordered[i];
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              height: heights[i],
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors[i].withOpacity(0.2),
                    colors[i].withOpacity(0.06),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(
                    color: colors[i].withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(medals[i], style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    e.userId.length > 6
                        ? e.userId.substring(0, 6)
                        : e.userId,
                    style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _fmt(e.lifetimePoints),
                    style: TextStyle(
                        color: colors[i],
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final _LeaderboardEntry entry;
  final bool isCurrentUser;
  final Color primaryColor, textColor;

  const _RankRow({
    required this.entry,
    required this.isCurrentUser,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(color: primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                  color: isCurrentUser
                      ? primaryColor
                      : textColor.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: isCurrentUser
                ? primaryColor
                : textColor.withOpacity(0.1),
            child: Text(
              entry.userId.substring(0, 1).toUpperCase(),
              style: TextStyle(
                  color: isCurrentUser
                      ? Colors.white
                      : textColor.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCurrentUser ? 'You' : entry.userId,
              style: TextStyle(
                  color: isCurrentUser
                      ? textColor
                      : textColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: isCurrentUser
                      ? FontWeight.w700
                      : FontWeight.w400),
            ),
          ),
          Text(
            _fmt(entry.lifetimePoints),
            style: TextStyle(
                color: isCurrentUser
                    ? primaryColor
                    : textColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _UserRankBanner extends StatelessWidget {
  final _LeaderboardEntry entry;
  final Color primaryColor, textColor;

  const _UserRankBanner({
    required this.entry,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Text('Your rank',
              style: TextStyle(
                  color: textColor.withOpacity(0.6), fontSize: 11)),
          const Spacer(),
          Text('#${entry.rank}',
              style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          Text(_fmt(entry.lifetimePoints),
              style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: Badges grid
// ─────────────────────────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final _Section section;
  final GamificationProfile? profile;
  final Color cardColor, accentColor, textColor;
  final double radius;
  final int columns;
  final bool showLocked;

  const _BadgesSection({
    required this.section,
    required this.profile,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    required this.radius,
    required this.columns,
    required this.showLocked,
  });

  @override
  Widget build(BuildContext context) {
    final badges      = profile?.badges ?? [];
    final lockedCount = (showLocked && badges.isNotEmpty) ? 3 : 0;
    final totalCount  = badges.length + lockedCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(section.title,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badges.isNotEmpty
                      ? accentColor.withOpacity(0.15)
                      : textColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${badges.length}',
                  style: TextStyle(
                      color: badges.isNotEmpty
                          ? accentColor
                          : textColor.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (badges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text('🏅',
                        style: TextStyle(
                            fontSize: 32,
                            color: textColor.withOpacity(0.2))),
                    const SizedBox(height: 8),
                    Text('No badges yet — keep going!',
                        style: TextStyle(
                            color: textColor.withOpacity(0.3),
                            fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount  : columns,
                crossAxisSpacing: 8,
                mainAxisSpacing : 8,
                childAspectRatio: 1,
              ),
              itemCount: totalCount,
              itemBuilder: (_, i) {
                if (i < badges.length) {
                  return _BadgeTile(
                      badge      : badges[i],
                      accentColor: accentColor,
                      textColor  : textColor);
                }
                return _LockedBadgeTile(textColor: textColor);
              },
            ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final UserBadge badge;
  final Color accentColor, textColor;

  const _BadgeTile({
    required this.badge,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          badge.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    badge.imageUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.military_tech_rounded,
                        color: accentColor,
                        size: 28),
                  ),
                )
              : Icon(Icons.military_tech_rounded,
                  color: accentColor, size: 28),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              badge.name.isNotEmpty ? badge.name : '#${badge.badgeId}',
              style: TextStyle(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBadgeTile extends StatelessWidget {
  final Color textColor;
  const _LockedBadgeTile({required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: textColor.withOpacity(0.08),
              width: 1,
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded,
                color: textColor.withOpacity(0.15), size: 22),
            const SizedBox(height: 6),
            Text('Locked',
                style: TextStyle(
                    color: textColor.withOpacity(0.15), fontSize: 9)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: Stats
// ─────────────────────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final _Section section;
  final GamificationProfile? profile;
  final PointsBalance? points;
  final _LeaderboardData? leaderboard;
  final Color cardColor, textColor, accentColor;
  final double radius;

  const _StatsSection({
    required this.section,
    required this.profile,
    required this.points,
    required this.leaderboard,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('💰', _fmt(points?.lifetimeEarned ?? 0), 'Total pts'),
      ('🏅', '${profile?.badges.length ?? 0}', 'Badges'),
      if (leaderboard?.userRank != null)
        ('🏆', '#${leaderboard!.userRank!.rank}', 'Rank'),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 14),
          Row(
            children: stats
                .map((s) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.14),
                              accentColor.withOpacity(0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: accentColor.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Text(s.$1,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text(s.$2,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                            Text(s.$3,
                                style: TextStyle(
                                    color: textColor.withOpacity(0.45),
                                    fontSize: 9,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: Activity
// ─────────────────────────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  final _Section section;
  final Color cardColor, textColor, accentColor;
  final double radius;

  const _ActivitySection({
    required this.section,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 12),
          Text('Recent events appear here',
              style: TextStyle(
                  color: textColor.withOpacity(0.3), fontSize: 12)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _hex(String h) {
  final s = h.replaceFirst('#', '');
  if (s.length == 6) return Color(int.parse('FF$s', radix: 16));
  if (s.length == 8) return Color(int.parse(s, radix: 16));
  return const Color(0xFF6366F1);
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}