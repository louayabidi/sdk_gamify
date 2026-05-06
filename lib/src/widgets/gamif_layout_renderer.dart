// lib/src/widgets/gamif_layout_renderer.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import '../gamification_sdk.dart';
import '../models.dart';
import 'gamif_points_widget.dart' show gamifRefreshController;

const double _kCanvasW = 300.0;
const double _kCanvasH = 520.0;
const double _kAspect  = _kCanvasW / _kCanvasH; // ≈ 0.577

// ─────────────────────────────────────────────────────────────────────────────

class GamifLayoutRenderer extends StatefulWidget {
  final String  layoutJson;
  final bool    animate;

  /// Hard cap on how wide the widget may grow (optional).
  final double? maxWidth;

  /// Hard cap on how tall the widget may grow (optional).
  final double? maxHeight;

  const GamifLayoutRenderer({
    super.key,
    required this.layoutJson,
    this.animate  = true,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  State<GamifLayoutRenderer> createState() => _GamifLayoutRendererState();
}

class _GamifLayoutRendererState extends State<GamifLayoutRenderer>
    with SingleTickerProviderStateMixin {

  PointsBalance?        _points;
  GamificationProfile?  _profile;
  bool                  _loading = true;
  StreamSubscription<void>? _refreshSub;

  late AnimationController _bannerCtrl;
  late Animation<double>   _bannerSlide;
  late Animation<double>   _bannerFade;
  GamificationReward?      _pendingReward;

  Map<String, dynamic> _frame    = {'bg': '#12122A', 'radius': 20};
  List<dynamic>        _elements = [];

  @override
  void initState() {
    super.initState();

    try {
      final parsed = jsonDecode(widget.layoutJson) as Map<String, dynamic>;
      _frame    = (parsed['frame']    as Map<String, dynamic>?) ?? _frame;
      _elements = (parsed['elements'] as List<dynamic>?)        ?? [];
    } catch (e) {
      debugPrint('[GamifLayoutRenderer] JSON parse error: $e');
    }

    _bannerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _bannerSlide = Tween<double>(begin: 72.0, end: 0.0).animate(
        CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOutCubic));
    _bannerFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _bannerCtrl,
            curve: const Interval(0.0, 0.4)));

    _fetchData();
    _refreshSub = gamifRefreshController.stream.listen((_) => _fetchData());

    if (GamificationSDK.isInitialized) {
      final prev = GamificationSDK.instance.onRewardReceived;
      GamificationSDK.instance.onRewardReceived = (reward) {
        prev?.call(reward);
        if (reward.isBadge && widget.animate && mounted) {
          _showBadgeUnlock(reward);
        }
      };
    }
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        GamificationSDK.instance.getPoints(),
        GamificationSDK.instance.getUserProfile(),
      ]);
      if (mounted) {
        setState(() {
          _points  = results[0] as PointsBalance;
          _profile = results[1] as GamificationProfile;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[GamifLayoutRenderer] fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showBadgeUnlock(GamificationReward reward) {
    setState(() => _pendingReward = reward);
    _bannerCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        _bannerCtrl.reverse().then((_) {
          if (mounted) setState(() => _pendingReward = null);
        });
      });
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final frameBg     = _hexColor(_frame['bg'] as String? ?? '#12122A');
    final frameRadius = (_frame['radius'] as num?)?.toDouble() ?? 20.0;

    // The native 300×520 canvas — FittedBox will scale this down.
    final nativeCanvas = SizedBox(
      width : _kCanvasW,
      height: _kCanvasH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(frameRadius),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color       : frameBg,
                  borderRadius: BorderRadius.circular(frameRadius),
                  boxShadow   : const [
                    BoxShadow(
                      color     : Color(0x40000000),
                      blurRadius: 24,
                      offset    : Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            // Elements
            if (_loading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              ..._elements.map((raw) => _CanvasElement(
                    el     : raw as Map<String, dynamic>,
                    points : _points,
                    profile: _profile,
                  )),
            // Badge-unlock banner
            if (_pendingReward != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: AnimatedBuilder(
                  animation: _bannerCtrl,
                  builder  : (_, __) => Transform.translate(
                    offset: Offset(0, _bannerSlide.value),
                    child : Opacity(
                      opacity: _bannerFade.value,
                      child  : _BadgeUnlockBanner(reward: _pendingReward!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // ── Sizing logic ─────────────────────────────────────────────────────────
    //
    // Problem: LayoutBuilder inside a Column/ListView gets INFINITE constraints.
    // FittedBox + SizedBox(infinite) = crash ("BoxConstraints forces infinite width").
    //
    // Fix:
    //  1. When constraints are infinite, fall back to MediaQuery screen size.
    //  2. Apply widget.maxWidth / widget.maxHeight caps.
    //  3. Pick the scale that fits BOTH axes (BoxFit.contain math, manual).
    //  4. Give FittedBox an explicit finite SizedBox — it never sees infinity.

    return LayoutBuilder(builder: (ctx, constraints) {
      final screen = MediaQuery.of(ctx).size;

      // Resolve available width — never infinite
      double availW = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : (widget.maxWidth ?? screen.width);
      if (widget.maxWidth != null) availW = availW.clamp(0, widget.maxWidth!);

      // Resolve available height — never infinite.
      // When unconstrained (Column), derive from width to keep aspect ratio.
      double availH = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : (widget.maxHeight ?? availW / _kAspect);
      if (widget.maxHeight != null) availH = availH.clamp(0, widget.maxHeight!);

      // BoxFit.contain: scale uniformly so canvas fits in (availW × availH)
      final scale   = (availW / _kCanvasW).clamp(0.0, availH / _kCanvasH);
      final displayW = _kCanvasW * scale;
      final displayH = _kCanvasH * scale;

      return SizedBox(
        width : displayW,
        height: displayH,
        child : FittedBox(
          fit      : BoxFit.fill, // SizedBox already has the right ratio
          alignment: Alignment.topCenter,
          child    : nativeCanvas,
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CanvasElement — placed at native 300×520 coordinates (no manual scaling)
// ─────────────────────────────────────────────────────────────────────────────

class _CanvasElement extends StatelessWidget {
  final Map<String, dynamic> el;
  final PointsBalance?       points;
  final GamificationProfile? profile;

  const _CanvasElement({
    required this.el,
    required this.points,
    required this.profile,
  });

  double _n(String k) => ((el[k] as num?) ?? 0).toDouble();
  Color  _c(String k, String fb) => _hexColor(el[k] as String? ?? fb);

  @override
  Widget build(BuildContext context) {
    final type = el['type'] as String? ?? '';
    final r    = _n('r').clamp(0.0, 999.0);

    return Positioned(
      left: _n('x'), top: _n('y'), width: _n('w'), height: _n('h'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: _build(type, _c('bg', '#00000000'), _c('fg', '#FFFFFF'), _c('ac', '#6366F1')),
      ),
    );
  }

  Widget _build(String type, Color bg, Color fg, Color ac) {
    final label = el['label'] as String? ?? '';
    final fs    = ((el['fs'] as num?)?.toDouble() ?? 12);

    switch (type) {

      case 'points':
        final balance = profile?.points ?? points?.balance ?? 0;
        return Container(
          color  : bg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child  : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fmtNum(balance),
                      style: TextStyle(color: fg, fontSize: 17,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  Text(label.isEmpty ? 'Points' : label,
                      style: TextStyle(color: fg.withOpacity(0.6),
                          fontSize: 9, letterSpacing: 1)),
                ],
              ),
            ],
          ),
        );

      case 'streak':
        return Container(
          color  : bg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child  : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${el['val'] ?? '0'} Days',
                      style: TextStyle(color: fg, fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  Text('CURRENT STREAK',
                      style: TextStyle(color: fg.withOpacity(0.6),
                          fontSize: 9, letterSpacing: 1)),
                ],
              ),
            ],
          ),
        );

      case 'level':
        return Container(
          color    : bg,
          alignment: Alignment.center,
          child    : Text('🎖️ ${el['val'] ?? 'Gold'}',
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
        );

      case 'badge':
        final earnedName = (profile?.badges.isNotEmpty == true)
            ? profile!.badges.first.name : null;
        final displayName = (earnedName?.isNotEmpty == true)
            ? earnedName! : (label.isNotEmpty ? label : 'No badge yet');
        return Container(
          decoration: BoxDecoration(
            border      : Border.all(color: ac, width: 1.5),
            borderRadius: BorderRadius.circular(_n('r').clamp(0, 999)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: ac, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(displayName, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

      case 'progress':
        final pct = ((el['pct'] as num?)?.toDouble() ?? 65) / 100;
        return Container(
          color  : bg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child  : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label.isEmpty ? 'Progress' : label,
                      style: TextStyle(color: fg, fontSize: 11)),
                  Text('${(pct * 100).round()}%',
                      style: TextStyle(color: ac, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value          : pct,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor     : AlwaysStoppedAnimation<Color>(ac),
                  minHeight      : 5,
                ),
              ),
            ],
          ),
        );

      case 'avatar':
        final initial = (GamificationSDK.isInitialized &&
                GamificationSDK.instance.currentUserId != null)
            ? GamificationSDK.instance.currentUserId!.substring(0, 1).toUpperCase()
            : (el['val'] as String? ?? 'A');
        return Container(
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment : Alignment.center,
          child     : Text(initial,
              style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w800)),
        );

      case 'label':
        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child  : Text(el['val'] as String? ?? '',
                style: TextStyle(color: fg, fontSize: fs, fontWeight: FontWeight.w600)),
          ),
        );

      case 'divider':
        return Container(
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(999)));

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BadgeUnlockBanner
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeUnlockBanner extends StatelessWidget {
  final GamificationReward reward;
  const _BadgeUnlockBanner({required this.reward});

  @override
  Widget build(BuildContext context) {
    final name = reward.badgeName ?? reward.message;
    return Container(
      margin    : const EdgeInsets.all(10),
      padding   : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient    : const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow   : const [BoxShadow(
            color: Color(0x886366F1), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize      : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎉 Badge Unlocked!',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 13)),
                if (name != null && name.isNotEmpty)
                  Text(name,
                      style   : const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
Color _hexColor(String hex) {
  final s = hex.replaceFirst('#', '');
  if (s.length == 6) return Color(int.parse('FF$s', radix: 16));
  if (s.length == 8) return Color(int.parse(s,      radix: 16));
  return Colors.transparent;
}

String _fmtNum(int n) {
  if (n >= 1000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  return n.toString();
}