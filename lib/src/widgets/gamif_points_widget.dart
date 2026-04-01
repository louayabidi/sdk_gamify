import 'package:flutter/material.dart';
import 'dart:async';
import '../gamification_sdk.dart';
import '../models.dart';

// ✅ Stream global — déclenché à chaque nouvelle récompense
final StreamController<void> _pointsRefreshController =
    StreamController<void>.broadcast();

// Appelé par GamifTracker après chaque track() réussi
void notifyPointsUpdated() {
  if (!_pointsRefreshController.isClosed) {
    _pointsRefreshController.add(null);
  }
}

class GamifPointsWidget extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final String label;
  final bool showLifetime;

  const GamifPointsWidget({
    super.key,
    this.backgroundColor = const Color(0xFF6C63FF),
    this.textColor = Colors.white,
    this.label = 'Points',
    this.showLifetime = false,
  });

  @override
  State<GamifPointsWidget> createState() => _GamifPointsWidgetState();
}

class _GamifPointsWidgetState extends State<GamifPointsWidget> {
  PointsBalance? _points;
  bool _loading = true;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _fetchPoints();

    // ✅ Écouter les nouvelles récompenses → refresh automatique
    _sub = _pointsRefreshController.stream.listen((_) {
      _fetchPoints();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchPoints() async {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      setState(() => _loading = false);
      return;
    }
    try {
      final points = await GamificationSDK.instance.getPoints();
      if (mounted) setState(() { _points = points; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GamificationSDK.isInitialized || !GamificationSDK.instance.hasUser) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _fetchPoints,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: widget.textColor),
      );
    }

    if (_points == null) {
      return Icon(Icons.star, color: widget.textColor, size: 18);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 6),
        Text(
          '${_points!.balance} ${widget.label}',
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (widget.showLifetime) ...[
          const SizedBox(width: 6),
          Text(
            '(${_points!.lifetimeEarned} total)',
            style: TextStyle(
              color: widget.textColor.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}