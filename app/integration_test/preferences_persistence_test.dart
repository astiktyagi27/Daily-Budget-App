import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/shell.dart';
import '../test/support/p1_screens.dart';
import 'real_preferences.dart';

// Literals from F-002 §5 and design-system.md §2 (never the app's constants).
const _dimBackground = 0xFF2A2825;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-002-11 theme choice persists with the real preferences '
      'plugin', (tester) async {
    final semantics = tester.ensureSemantics();
    await clearRealPreferences();
    addTearDown(clearRealPreferences);

    // Fresh install: finish onboarding, then pick Dim in Settings.
    await restartOnRealStore(tester, settle: true);
    for (final label in ['Skip', 'Not now', 'Not now', 'I understand']) {
      await tapOnboardingButton(tester, label);
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tapTab(tester, 'Settings');
    await openThemePicker(tester);
    await pickTheme(tester, 'Dim');
    expect(pageBackground(tester), _dimBackground);
    await closeThemePicker(tester);
    await expectSavedString('theme.choice', 'dim');

    // New app on a new store instance from the plugin: Dim on the first frame.
    await restartOnRealStore(tester);
    expect(
      pageBackground(tester),
      _dimBackground,
      reason: 'first frame after the restart',
    );
    await tester.pumpAndSettle();
    await tapTab(tester, 'Settings');
    await openThemePicker(tester);
    expect(
      tester.getSemantics(pickerOption('Dim')),
      isSemantics(
        label: 'Dim. Soft warm grey, easy on the eyes',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
