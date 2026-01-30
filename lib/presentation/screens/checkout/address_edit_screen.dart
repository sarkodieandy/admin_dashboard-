import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../providers/address_provider.dart';
import '../../../domain/entities/address.dart';

class AddressEditScreen extends StatefulWidget {
  const AddressEditScreen({super.key, this.initial});

  static const routePath = '/address/edit';

  final Address? initial;

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  String _labelPreset = 'Home';
  final _customLabel = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _labelPreset = (initial.label.trim().isEmpty ? 'Home' : initial.label.trim());
      if (!['Home', 'Work'].contains(_labelPreset)) {
        _customLabel.text = _labelPreset;
        _labelPreset = 'Custom';
      }
      _address.text = initial.address;
      _landmark.text = initial.landmark ?? '';
      _isDefault = initial.isDefault;
    }
  }

  @override
  void dispose() {
    _customLabel.dispose();
    _address.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelPreset == 'Custom' ? _customLabel.text.trim() : _labelPreset;
    final address = _address.text.trim();
    final landmark = _landmark.text.trim();

    if (label.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label and address are required.')),
      );
      return;
    }

    final ok = await context.read<AddressProvider>().saveAddress(
          id: widget.initial?.id,
          label: label,
          address: address,
          landmark: landmark,
          isDefault: _isDefault,
        );

    if (!mounted) return;
    if (!ok) {
      final error = context.read<AddressProvider>().error ?? AppStrings.somethingWentWrong;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Add address' : 'Edit address'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Label',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.x10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final preset in const ['Home', 'Work', 'Custom'])
                    ChoiceChip(
                      selected: _labelPreset == preset,
                      onSelected: provider.isLoading ? null : (_) => setState(() => _labelPreset = preset),
                      label: Text(preset),
                    ),
                ],
              ),
              if (_labelPreset == 'Custom') ...[
                const SizedBox(height: AppSpacing.x12),
                AppTextField(controller: _customLabel, label: 'Custom label'),
              ],
              const SizedBox(height: AppSpacing.x12),
              AppTextField(controller: _address, label: 'Address'),
              const SizedBox(height: AppSpacing.x12),
              AppTextField(
                controller: _landmark,
                label: 'Landmark note',
                hintText: AppStrings.landmarkHint,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.x12),
              SwitchListTile.adaptive(
                value: _isDefault,
                onChanged: provider.isLoading ? null : (v) => setState(() => _isDefault = v),
                title: const Text('Make default'),
                subtitle: Text(
                  'Used automatically at checkout.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const Spacer(),
              AppButton(
                label: widget.initial == null ? 'Save address' : 'Save changes',
                isLoading: provider.isLoading,
                onPressed: provider.isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

