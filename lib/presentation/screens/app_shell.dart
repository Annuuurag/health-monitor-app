import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import 'care_screen.dart';
import 'dashboard_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(controller: controller),
      ReportsScreen(controller: controller),
      CareScreen(controller: controller),
      InsightsScreen(controller: controller),
      ProfileScreen(controller: controller),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[controller.selectedTab],
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: controller.selectedTab,
        onTap: controller.selectTab,
      ),
    );
  }
}
