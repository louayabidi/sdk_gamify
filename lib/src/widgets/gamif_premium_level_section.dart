// lib/src/widgets/gamif_premium_level_section.dart
// Enhanced Level Section with Premium Widgets

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../gamification_sdk.dart';
import '../models.dart';
import 'gamif_points_widget.dart' show gamifRefreshController;
import 'gamif_premium_level_widget.dart';

/// Get title from levelTitlesJson for a specific level
String? _getTitleForLevel(UserLevelInfo level) {
  if (level.levelTitlesJson == null || level.levelTitlesJson!.isEmpty) return null;
  try {
    final map = jsonDecode(level.levelTitlesJson!) as Map<String, dynamic>;
    return map['${level.currentLevel}'] as String?;
  } catch (_) {
    return null;
  }
}

/// Premium Level Section with smooth animations and tier-based visuals
class GamifPremiumLevelSection extends StatefulWidget {
  final String title;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final double radius;

  const GamifPremiumLevelSection({
    super.key,
    required this.title,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.radius,
  });

  @override
  State<GamifPremiumLevelSection> createState() =>
      _GamifPremiumLevelSectionState();
}

class _GamifPremiumLevelSectionState extends State<GamifPremiumLevelSection>
    with SingleTickerProviderStateMixin {
  List<UserLevelInfo> _levels = [];
  bool _loading = true;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _fetchLevels();
    _sub = gamifRefreshController.stream.listen((_) => _fetchLevels());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLevels() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final levels = await GamificationSDK.instance.getLevels();
      if (mounted) setState(() { _levels = levels; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎖️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_levels.isEmpty)
            Text(
              'No level system configured for this app.',
              style: TextStyle(
                color: widget.textColor.withOpacity(0.35),
                fontSize: 12,
              ),
            )
          else
            ..._levels.map((l) => PremiumLevelCard(
              level: l,
              textColor: widget.textColor,
              titleOverride: _getTitleForLevel(l),
            )),
        ],
      ),
    );
  }
}