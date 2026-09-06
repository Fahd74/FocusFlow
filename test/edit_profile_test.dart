import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

import 'package:focus_flow/app/focus_flow_app.dart';
import 'package:focus_flow/core/data/focus_flow_repository.dart';
import 'package:focus_flow/core/data/local/focus_flow_database.dart';
import 'package:focus_flow/core/domain/services/preferences_service.dart';

void main() {
  late SharedPreferences prefs;
  late PreferencesService preferencesService;
  late FocusFlowDatabase database;
  late FocusFlowRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    preferencesService = PreferencesService(prefs);
    database = FocusFlowDatabase.forTesting(NativeDatabase.memory());
    repository = FocusFlowRepository(database: database);
    await repository.ready;
  });

  tearDown(() async {
    repository.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest() {
    return FocusFlowApp(
      repository: repository,
      preferencesService: preferencesService,
      disablePolling: true,
    );
  }

  testWidgets('Guest user can customize profile name and email locally', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Navigate to Profile Screen
    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle();
    expect(find.text('Guest User'), findsWidgets);

    // 2. Click Edit Profile
    final editProfileButton = find.text('Edit Profile');
    await tester.ensureVisible(editProfileButton);
    await tester.pumpAndSettle();
    await tester.tap(editProfileButton);
    await tester.pumpAndSettle();

    // 3. Verify fields load default guest data
    expect(find.text('Guest User'), findsWidgets);
    expect(find.text('guest@focusflow.ai'), findsWidgets);

    // 4. Update the name fields
    final firstNameField = find.byKey(const Key('edit_profile_first_name'));
    await tester.enterText(firstNameField, 'Fahd');
    await tester.pumpAndSettle();

    final lastNameField = find.byKey(const Key('edit_profile_last_name'));
    await tester.enterText(lastNameField, 'Al-Amri');
    await tester.pumpAndSettle();

    final displayNameField = find.byKey(const Key('edit_profile_display_name'));
    await tester.enterText(displayNameField, 'Fahd Al-Amri');
    await tester.pumpAndSettle();

    // 5. Click Save Changes
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // 6. Verify redirected to Profile Screen showing updated name and original email (read-only)
    expect(find.text('Fahd Al-Amri'), findsWidgets);
    expect(find.text('guest@focusflow.ai'), findsWidgets);

    // 7. Verify local preferences are updated
    expect(preferencesService.guestName, 'Fahd Al-Amri');
    expect(preferencesService.guestFirstName, 'Fahd');
    expect(preferencesService.guestLastName, 'Al-Amri');
    expect(preferencesService.guestEmail, 'guest@focusflow.ai');
  });
}
