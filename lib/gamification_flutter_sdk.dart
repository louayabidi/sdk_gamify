library gamification_flutter_sdk;

export 'src/gamification_sdk.dart'
    show GamificationSDK, OnRewardReceived;

export 'src/models.dart'
    show GamificationReward, GamificationProfile, UserBadge;

export 'src/exceptions.dart'
    show
        SdkNotInitializedException,   //  Erreur 1: SDK pas initialisé
        NoUserIdentifiedException,    //  Erreur 2: Pas d'utilisateur identifié
        GamificationApiException,     //  Erreur 3: Problème API Backend retourne 401 (clé API invalide)
        GamificationNetworkException;  //  Erreur 4: Pas d'internet  Timeout après 15 secondes





export 'src/gamif_tracker.dart' show GamifSDK, GamifTracker;

export 'src/widgets/gamif_points_widget.dart';

export 'src/widgets/gamif_widget.dart'
    show GamifWidget, GamifDisplay, GamifContent, GamifWidgetConfig , GamifWidgetDisplay;

export 'src/widgets/gamif_badge_widget.dart' show GamifBadgeWidget;

export 'src/widgets/gamif_page.dart';

export 'src/widgets/gamif_layout_renderer.dart'; // GamifLayoutRenderer
export 'src/widgets/gamif_widget_config.dart';   // GamifWidgetConfig, GamifDisplay, GamifContent



export 'src/widgets/gamif_celebration_overlay.dart'  // ← THIS was missing
    show GamifCelebrationOverlay;