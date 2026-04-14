import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../domain/models/user_profile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.userProfile;
    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _genderController = TextEditingController(text: profile.gender);
    _heightController = TextEditingController(
      text: profile.heightCm.toString(),
    );
    _weightController = TextEditingController(
      text: profile.weightKg.toString(),
    );
    _contactController = TextEditingController(text: profile.emergencyContact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'User profile',
      body: Column(
        children: [
          _field('Name', _nameController),
          _field('Age', _ageController, keyboardType: TextInputType.number),
          _field('Gender', _genderController),
          _field(
            'Height',
            _heightController,
            keyboardType: TextInputType.number,
          ),
          _field(
            'Weight',
            _weightController,
            keyboardType: TextInputType.number,
          ),
          _field(
            'Phone',
            _contactController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _save() async {
    final profile = UserProfile(
      name: _nameController.text.trim(),
      age:
          int.tryParse(_ageController.text) ??
          widget.controller.userProfile.age,
      gender: _genderController.text.trim(),
      heightCm:
          int.tryParse(_heightController.text) ??
          widget.controller.userProfile.heightCm,
      weightKg:
          int.tryParse(_weightController.text) ??
          widget.controller.userProfile.weightKg,
      emergencyContact: _contactController.text.trim(),
    );

    await widget.controller.updateUserProfile(profile);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }
}
