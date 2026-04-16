import 'package:flutter/material.dart';
import '../gamification_sdk.dart';
import '../models.dart';
import 'gamif_widget_config.dart';
import 'gamif_points_widget.dart';
import 'gamif_badge_widget.dart';

class GamifWidget extends StatefulWidget {
  /// The publishable key from your dashboard.
  final String apiKey;

  /// Optional: Override config locally (for testing).
  final GamifWidgetConfig? localConfig;

  const GamifWidget({
    super.key,
    required this.apiKey,
    this.localConfig,
  });

  @override
  State<GamifWidget> createState() => _GamifWidgetState();
}

class _GamifWidgetState extends State<GamifWidget> {
  GamifWidgetConfig? _config;
  bool _loadingConfig = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      if (widget.localConfig != null) {
        print('[GamifWidget] ✅ Using local config');
        setState(() {
          _config = widget.localConfig;
          _loadingConfig = false;
        });
        return;
      }

      final sdk = GamificationSDK.instance;
      final widgetConfig = await sdk.getWidgetConfig(widget.apiKey);

      Color _hexToColor(String hex) {
        final cleaned = hex.replaceFirst('#', '');
        return Color(int.parse(cleaned, radix: 16) + 0xFF000000);
      }

      setState(() {
        _config = GamifWidgetConfig(
          backgroundColor: _hexToColor(widgetConfig.backgroundColor),
          textColor: _hexToColor(widgetConfig.textColor),
          accentColor: _hexToColor(widgetConfig.accentColor),
          label: widgetConfig.label,
          showLifetime: widgetConfig.showLifetime,
          showLevel: widgetConfig.showLevel,
          animate: widgetConfig.animate,
          borderRadius: widgetConfig.borderRadius.toDouble(),
        );
        _loadingConfig = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingConfig = false;
      });
    }
  }

@override
Widget build(BuildContext context) {
  if (_loadingConfig) {
    return const SizedBox(width: 20, height: 20,
      child: CircularProgressIndicator(strokeWidth: 2));
  }

  if (_error != null || _config == null) {
    // In development, show the error; in production, hide it
    assert(() {
      debugPrint('[GamifWidget] Error: $_error');
      return true;
    }());
    return const SizedBox.shrink();
  }

  return _buildWidget(_config!);
}

Widget _buildWidget(GamifWidgetConfig config) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // In AppBar actions, height is ~32-48px — render pill only
      final isConstrained = constraints.maxHeight < 60;

      if (isConstrained) {
        return GamifPointsWidget(
          backgroundColor: config.backgroundColor,
          textColor: config.textColor,
          label: config.label,
          showLifetime: false, // no room
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GamifPointsWidget(
              backgroundColor: config.backgroundColor,
              textColor: config.textColor,
              label: config.label,
              showLifetime: config.showLifetime,
            ),
            const SizedBox(height: 8),
            GamifBadgeWidget(
              backgroundColor: config.backgroundColor,
              textColor: config.textColor,
              accentColor: config.accentColor,
              compact: true,
            ),
          ],
        ),
      );
    },
  );
}
}