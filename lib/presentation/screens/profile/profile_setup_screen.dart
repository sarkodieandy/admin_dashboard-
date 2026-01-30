import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../providers/profile_provider.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const routePath = '/profile/setup';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  bool _didPrefill = false;

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final note = _note.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required.')),
      );
      return;
    }

    final ok = await context.read<ProfileProvider>().updateMyProfile(
          name: name,
          phone: phone,
          defaultDeliveryNote: note,
        );

    if (!mounted) return;
    if (!ok) {
      final error = context.read<ProfileProvider>().error ?? AppStrings.somethingWentWrong;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.go(HomeScreen.routePath);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    if (profile != null && !_didPrefill) {
      _name.text = profile.name ?? '';
      _phone.text = profile.phone ?? '';
      _note.text = profile.defaultDeliveryNote ?? '';
      _didPrefill = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileSetupTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            children: [
              AppTextField(controller: _name, label: AppStrings.name),
              const SizedBox(height: AppSpacing.x12),
              AppTextField(
                controller: _phone,
                label: AppStrings.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.x12),
              AppTextField(
                controller: _note,
                label: AppStrings.defaultDeliveryNote,
                hintText: AppStrings.landmarkHint,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.x16),
              AppButton(
                label: AppStrings.continueText,
                isLoading: profileProvider.isLoading,
                onPressed: profileProvider.isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
