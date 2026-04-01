// Tests basiques du SDK — on vérifie juste que les imports fonctionnent.
import 'package:flutter_test/flutter_test.dart';
import 'package:gamification_flutter_sdk/gamification_flutter_sdk.dart';

void main() {
  test('SDK is not initialized by default', () {
    expect(GamificationSDK.isInitialized, false);
  });
}