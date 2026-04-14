import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_monitor_app/app/app.dart';
import 'package:health_monitor_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the dashboard shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final controller = createAppController(
      notificationService: NoopNotificationService(),
    );

    await tester.pumpWidget(HealthMonitorApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Today\'s summary'), findsOneWidget);
    expect(find.text('Key vitals'), findsOneWidget);
  });
}
