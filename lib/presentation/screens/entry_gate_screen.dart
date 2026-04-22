import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import 'app_shell.dart';
import 'auth_screen.dart';
import 'device_pairing_flow_screen.dart';
import 'onboarding_screen.dart';

class EntryGateScreen extends StatelessWidget {
  const EntryGateScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!controller.settings.hasCompletedOnboarding) {
      return OnboardingScreen(controller: controller);
    }

    if (!controller.settings.isSignedIn) {
      return AuthScreen(controller: controller);
    }

    if (!controller.settings.hasCompletedPairing) {
      return DevicePairingFlowScreen(controller: controller);
    }

    return AppShell(controller: controller);
  }
}
