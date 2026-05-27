import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _profileImagePath;
  bool _isEditing = false;

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
    _profileImagePath = profile.profileImagePath;
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
    final profile = widget.controller.userProfile;
    return ScreenScaffold(
      title: 'User profile',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 88,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : const Color(0xFFE2E8F0),
                backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                    : null,
                child: _profileImagePath == null
                    ? Icon(
                        Icons.person_outline,
                        size: 90,
                        color: AppColors.primaryText(context),
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            profile.name,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your details',
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_isEditing) {
                            // Revert changes if cancelled
                            final profile = widget.controller.userProfile;
                            _nameController.text = profile.name;
                            _ageController.text = profile.age.toString();
                            _genderController.text = profile.gender;
                            _heightController.text = profile.heightCm.toString();
                            _weightController.text = profile.weightKg.toString();
                            _contactController.text = profile.emergencyContact;
                            _profileImagePath = profile.profileImagePath;
                          }
                          _isEditing = !_isEditing;
                        });
                      },
                      child: Text(
                        _isEditing ? 'Cancel' : 'Edit',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _field('Name', _nameController),
                _field(
                  'Age',
                  _ageController,
                  keyboardType: TextInputType.number,
                ),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isEditing)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              enabled: _isEditing,
              controller: controller,
              keyboardType: keyboardType,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
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
      profileImagePath: _profileImagePath,
    );

    await widget.controller.updateUserProfile(profile);
    if (!mounted) {
      return;
    }
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }
}
