import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _gender;
  double? _bmi;
  bool _initialized = false;

  void _calculateBMI() {
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      if (!_initialized) {
        final profile = ref.read(profileProvider);
        if (profile != null) {
          _ageController.text = profile.age.toString();
          _weightController.text = profile.weight.toString();
          _heightController.text = profile.height.toString();
          _gender = profile.gender;
          _bmi = profile.bmi;
        }
        _initialized = true;
      }
    }

    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    if (weight != null && height != null && height > 0) {
      final bmi = weight / ((height / 100) * (height / 100));
      setState(() {
        _bmi = double.parse(bmi.toStringAsFixed(1));
      });
    } else {
      setState(() {
        _bmi = null;
      });
    }
  }

  Future<void> _saveProfile({bool skipped = false}) async {
    if (!skipped && _formKey.currentState!.validate()) {
      final profile = UserProfile(
        id: 'profile_1',
        age: int.parse(_ageController.text),
        gender: _gender!,
        weight: double.parse(_weightController.text),
        weightUnit: 'kg',
        height: double.parse(_heightController.text),
        heightUnit: 'cm',
        bmi: _bmi ?? 0,
        lastUpdated: DateTime.now(),
      );
      await ref.read(profileProvider.notifier).saveProfile(profile);
      await ref.read(onboardingCompleteProvider.notifier).setComplete(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile saved! BMI: ${profile.bmi}')),
        );
      }
    } else if (skipped) {
      await ref.read(profileProvider.notifier).clearProfile();
      await ref.read(onboardingCompleteProvider.notifier).setComplete(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skipped profile setup.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to FitRoute')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Let’s set up your profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 5 || n > 120) return 'Enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(labelText: 'Gender'),
                validator: (v) => v == null ? 'Select gender' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateBMI(),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 20 || n > 300)
                    return 'Enter a valid weight';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateBMI(),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 80 || n > 250)
                    return 'Enter a valid height';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_bmi != null)
                Text('BMI: ${_bmi!.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveProfile(),
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _saveProfile(skipped: true),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
