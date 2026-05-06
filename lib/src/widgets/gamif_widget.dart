// lib/src/widgets/gamif_widget.dart
//
// Inline gamification widget — three display modes.
// Use this inside AppBar, body cards, etc.
// For the full-screen rewards page, use GamifPage instead.

import 'dart:async';
import 'package:flutter/material.dart';
import '../gamification_sdk.dart';
import '../models.dart';
import 'gamif_widget_config.dart';
import 'gamif_points_widget.dart';
import 'gamif_badge_widget.dart';
import 'gamif_layout_renderer.dart';

// ── Display mode enum ─────────────────────────────────────────────────────────

enum GamifWidgetDisplay {
  /// Ultra-compact pill — perfect for AppBar actions. Self-sizes, never overflows.
  pill,
  /// Compact horizontal card — drops into any layout.
  card,
  /// Rich vertical panel — points + full badge list.
  full,
}

// ─────────────────────────────────────────────────────────────────────────────

class GamifWidget extends StatefulWidget {
  /// Publishable key from the Widget Studio in the dashboard.
  final String apiKey;

  /// Override the display mode locally.
  /// If not provided, the backend config's displayMode is used.
  final GamifWidgetDisplay? display;

  /// Optional fully-local config — skips all network calls.
  final GamifWidgetConfig? localConfig;

  const GamifWidget({
    super.key,
    required this.apiKey,
    this.display,
    this.localConfig,
  });

  @override
  State<GamifWidget> createState() => _GamifWidgetState();
}

class _GamifWidgetState extends State<GamifWidget>
    with SingleTickerProviderStateMixin {

  WidgetConfig?      _remote;
  GamifWidgetConfig? _local;
  GamifDisplay       _displayMode = GamifDisplay.card;
  GamifContent       _contentMode = GamifContent.both;
  bool               _loading     = true;
  String?            _error;

  // Points counter animation
  late AnimationController _counterCtrl;
  int _displayedPoints = 0;
  int _targetPoints    = 0;

  // Badge unlock toast
  GamificationReward? _toast;
  Timer?              _toastTimer;

  StreamSubscription<void>? _refreshSub;


  Widget _buildFallback(GamifWidgetConfig cfg) {
  final mode = widget.display ?? GamifWidgetDisplay.card;
  switch (mode) {
    case GamifWidgetDisplay.pill:
      return _buildPill(cfg.backgroundColor, cfg.textColor, cfg.accentColor, cfg.label);
    case GamifWidgetDisplay.card:
      return _buildCard(cfg.backgroundColor, cfg.textColor, cfg.accentColor,
          cfg.borderRadius, cfg.label, cfg.showLifetime, GamifContent.both);
    case GamifWidgetDisplay.full:
      return _buildFull(cfg.backgroundColor, cfg.textColor, cfg.accentColor,
          cfg.borderRadius, cfg.label, cfg.showLifetime, GamifContent.both);
  }
}

  @override
  void initState() {
    super.initState();
    _counterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _counterCtrl.addListener(() {
      final v = (_displayedPoints +
              (_targetPoints - _displayedPoints) *
                  Curves.easeOutCubic.transform(_counterCtrl.value))
          .round();
      if (mounted) setState(() => _displayedPoints = v);
    });

    _loadConfig();
    _refreshSub = gamifRefreshController.stream.listen((_) => _fetchLivePoints());

    if (GamificationSDK.isInitialized) {
      final prev = GamificationSDK.instance.onRewardReceived;
      GamificationSDK.instance.onRewardReceived = (reward) {
        prev?.call(reward);
        if (mounted) _showToast(reward);
      };
    }
  }

  @override
  void dispose() {
    _counterCtrl.dispose();
    _refreshSub?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (widget.localConfig != null) {
      if (mounted) setState(() { _local = widget.localConfig; _loading = false; });
      return;
    }
    try {
      final cfg = await GamificationSDK.instance.getWidgetConfig(widget.apiKey);
      _displayMode = _parseDisplay(cfg.displayMode);
      _contentMode = _parseContent(cfg.contentMode);
      if (mounted) setState(() { _remote = cfg; _loading = false; });
      await _fetchLivePoints();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _fetchLivePoints() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) return;
    try {
      final pts = await GamificationSDK.instance.getPoints();
      _targetPoints = pts.balance;
      _counterCtrl.forward(from: 0);
    } catch (_) {}
  }

  void _showToast(GamificationReward reward) {
    _toastTimer?.cancel();
    setState(() => _toast = reward);
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null || (_remote == null && _local == null)) {
      return const SizedBox.shrink();
    }

    // Local config path
    if (_local != null) return _buildFallback(_local!);

    final remote = _remote!;

    // If the backend saved a layoutJson canvas → use the renderer
    if (remote.layoutJson != null && remote.layoutJson!.isNotEmpty) {
      return GamifLayoutRenderer(
          layoutJson: remote.layoutJson!, animate: remote.animate);
    }

    // Fallback: pill / card / full
    final cfg     = _remoteToLocal(remote);
    // widget.display overrides backend setting
    final mode    = widget.display ?? _toGamifDisplay(_displayMode);
    final content = _contentMode;
    final bg      = cfg.backgroundColor;
    final fg      = cfg.textColor;
    final ac      = cfg.accentColor;
    final radius  = cfg.borderRadius;
    final label   = cfg.label;
    final showLife= cfg.showLifetime;

    switch (mode) {
      case GamifWidgetDisplay.pill:
        return _buildPill(bg, fg, ac, label);
      case GamifWidgetDisplay.card:
        return _buildCard(bg, fg, ac, radius, label, showLife, content);
      case GamifWidgetDisplay.full:
        return _buildFull(bg, fg, ac, radius, label, showLife, content);
    }
  }

  // ── Pill ──────────────────────────────────────────────────────────────────

  Widget _buildPill(Color bg, Color fg, Color ac, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: bg.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
          const SizedBox(width: 4),
          Text(
            _fmt(_displayedPoints),
            style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildCard(Color bg, Color fg, Color ac, double radius,
      String label, bool showLife, GamifContent content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [bg, Color.lerp(bg, Colors.black, 0.15)!],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(
            color: bg.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (content != GamifContent.badges) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(_fmt(_displayedPoints),
                      style: TextStyle(color: fg, fontSize: 22,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ]),
                Text(label,
                    style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11)),
              ],
            ),
          ],
          if (content != GamifContent.points)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GamifBadgeWidget(
                  backgroundColor: bg, textColor: fg,
                  accentColor: ac, compact: true),
            ),
        ],
      ),
    );
  }

  // ── Full ──────────────────────────────────────────────────────────────────

  Widget _buildFull(Color bg, Color fg, Color ac, double radius,
      String label, bool showLife, GamifContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [bg, Color.lerp(bg, Colors.black, 0.2)!],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(
            color: bg.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content != GamifContent.badges) ...[
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: fg.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('⭐', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fmt(_displayedPoints),
                    style: TextStyle(color: fg, fontSize: 28,
                        fontWeight: FontWeight.w900, letterSpacing: -1)),
                Text(label,
                    style: TextStyle(color: fg.withOpacity(0.6), fontSize: 13)),
              ]),
            ]),
            if (content == GamifContent.both)
              Divider(height: 20, color: fg.withOpacity(0.12)),
          ],
          if (content != GamifContent.points)
            GamifBadgeWidget(
                backgroundColor: bg, textColor: fg,
                accentColor: ac, compact: false),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  GamifWidgetConfig _remoteToLocal(WidgetConfig r) => GamifWidgetConfig(
    backgroundColor: _hexToColor(r.backgroundColor),
    textColor      : _hexToColor(r.textColor),
    accentColor    : _hexToColor(r.accentColor),
    label          : r.label,
    showLifetime   : r.showLifetime,
    showLevel      : r.showLevel,
    animate        : r.animate,
    borderRadius   : r.borderRadius.toDouble(),
  );

  GamifWidgetDisplay _toGamifDisplay(GamifDisplay d) {
    switch (d) {
      case GamifDisplay.pill: return GamifWidgetDisplay.pill;
      case GamifDisplay.full: return GamifWidgetDisplay.full;
      default               : return GamifWidgetDisplay.card;
    }
  }

  GamifDisplay _parseDisplay(String s) {
    switch (s.toLowerCase()) {
      case 'pill': return GamifDisplay.pill;
      case 'full': return GamifDisplay.full;
      default    : return GamifDisplay.card;
    }
  }

  GamifContent _parseContent(String s) {
    switch (s.toLowerCase()) {
      case 'points': return GamifContent.points;
      case 'badges': return GamifContent.badges;
      default       : return GamifContent.both;
    }
  }

  Color _hexToColor(String hex) {
    final s = hex.replaceFirst('#', '');
    if (s.length == 6) return Color(int.parse('FF$s', radix: 16));
    if (s.length == 8) return Color(int.parse(s, radix: 16));
    return const Color(0xFF6C63FF);
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}