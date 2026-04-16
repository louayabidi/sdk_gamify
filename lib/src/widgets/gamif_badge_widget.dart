import 'package:flutter/material.dart';
import 'dart:async';
import '../gamification_sdk.dart';
import '../models.dart';

import 'gamif_points_widget.dart' show gamifRefreshController;

class GamifBadgeWidget extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  /// pill mode: show as small chips
  /// card/full mode: show as list rows
  final bool compact;

  const GamifBadgeWidget({
    super.key,
    this.backgroundColor = const Color(0xFF6C63FF),
    this.textColor = Colors.white,
    this.accentColor = const Color(0xFF34D399),
    this.compact = true,
  });

  @override
  State<GamifBadgeWidget> createState() => _GamifBadgeWidgetState();
}

class _GamifBadgeWidgetState extends State<GamifBadgeWidget> {
  GamificationProfile? _profile;
  bool _loading = true;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profile = await GamificationSDK.instance.getUserProfile();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.accentColor,
        ),
      );
    }

    if (_profile == null || _profile!.badges.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      return _buildPillBadges();
    }
    return _buildListBadges();
  }

  // ── Compact pill chips (for pill + card modes) ──────────────────────────
  Widget _buildPillBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _profile!.badges.map((b) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.backgroundColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.backgroundColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.military_tech, size: 14, color: widget.accentColor),
              const SizedBox(width: 4),
              Text(
                'Badge #${b.badgeId}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.backgroundColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── List rows (for full mode) ───────────────────────────────────────────
  Widget _buildListBadges() {
    return Column(
      children: _profile!.badges.asMap().entries.map((entry) {
        final b = entry.value;
        final isLast = entry.key == _profile!.badges.length - 1;
        return Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: widget.textColor.withOpacity(0.1),
                    ),
                  ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.military_tech,
                  size: 18,
                  color: widget.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Badge #${b.badgeId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Earned ${b.awardedAt.split('T').first}',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}