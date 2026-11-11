import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/shell.dart';
import '../test/support/p1_screens.dart';
import 'real_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-005-16 onboarding flow persists with the real preferences '
      'plugin', (tester) async {
    await clearRealPreferences();
    addTearDown(clearRealPreferences);

    // Fresh install: slide 1 of the tour, no tab bar.
    await restartOnRealStore(tester, settle: true);
    expect(find.text('Skip'), findsOneWidget);
    expect(navBar, findsNothing);

    // Slide 1 -> Skip -> Not now -> Not now -> I understand -> Home.
    await tapOnboardingButton(tester, 'Skip');
    await expectSavedBool('onboarding.tour_seen', expected: true);
    expect(find.text('Allow SMS access'), findsOneWidget);
    await tapOnboardingButton(tester, 'Not now');
    expect(find.text('Turn on notifications'), findsOneWidget);
    await tapOnboardingButton(tester, 'Not now');
    await tapOnboardingButton(tester, 'I understand');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(navBar, findsOneWidget);
    await expectSavedBool('onboarding.finished', expected: true);

    // Rebuild in-process on a fresh store instance: Home, no tour.
    await restartOnRealStore(tester, settle: true);
    expect(navBar, findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Allow SMS access'), findsNothing);

    // Reset the flags to {tour seen}: the SMS explainer.
    final store = await openRealStore();
    await store.remove('onboarding.finished');
    await expectSavedBool('onboarding.tour_seen', expected: true);
    await restartOnRealStore(tester, settle: true);
    expect(find.text('Allow SMS access'), findsOneWidget);
    expect(navBar, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
