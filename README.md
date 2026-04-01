# gamification_flutter_sdk

Flutter SDK for the SaaS Gamification Platform. Add gamification to your Flutter app in minutes.

## Features

- 🎮 Track user events automatically
- 🏆 Receive rewards (points & badges) in real-time
- 👤 Identify users across sessions
- 🔑 Simple API key setup

## Installation
```yaml
dependencies:
  gamification_flutter_sdk: ^1.0.0
```

## Usage

### Initialize the SDK
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GamificationSDK.initialize(
    apiKey: 'your_api_key',
    baseUrl: 'https://your-backend.com',
    onReward: (rewards) {
      for (final r in rewards) {
        print('🏆 Reward: ${r.message}');
      }
    },
  );
  runApp(const MyApp());
}
```

### Identify a user
```dart
await GamificationSDK.instance.identify('user_123');
```

### Track an event
```dart
final rewards = await GamificationSDK.instance.track('completeLevel');
```

### Auto-injection via gamif_scanner
```sh
dart pub global activate gamif_scanner
dart pub global run gamif_scanner:setup .
```

## Requirements

- Flutter >= 3.10.0
- Dart >= 3.0.0
- A running Gamification backend