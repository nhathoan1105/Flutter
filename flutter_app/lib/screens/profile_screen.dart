import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _targetWeight = TextEditingController();
  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.light;
  Goal _goal = Goal.maintain;
  bool _initialized = false;
  double? _syncedWeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = AppScope.of(context).profile;
    // Weigh-ins from the weight tab update the profile; keep the field in sync.
    if (p != null && p.weightKg != _syncedWeight) {
      _syncedWeight = p.weightKg;
      _weight.text = _fmt(p.weightKg);
    }
    if (_initialized) return;
    _initialized = true;
    if (p != null) {
      _gender = p.gender;
      _activity = p.activityLevel;
      _goal = p.goal;
      _age.text = '${p.age}';
      _height.text = _fmt(p.heightCm);
      if (p.targetWeightKg != null) _targetWeight.text = _fmt(p.targetWeightKg!);
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  String? _validateNumber(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n == null) return 'Nhập một số';
    if (n < min || n > max) return 'Trong khoảng $min–$max';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    double parse(TextEditingController c) =>
        double.parse(c.text.replaceAll(',', '.'));
    await AppScope.of(context).saveProfile(UserProfile(
      gender: _gender,
      age: parse(_age).round(),
      heightCm: parse(_height),
      weightKg: parse(_weight),
      activityLevel: _activity,
      goal: _goal,
      targetWeightKg: _targetWeight.text.trim().isEmpty
          ? null
          : parse(_targetWeight),
    ));
    if (!mounted || widget.isOnboarding) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'Chào mừng đến Calo Fit' : 'Hồ sơ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.isOnboarding)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Nhập thông tin để tính lượng calo mỗi ngày phù hợp với bạn.',
                ),
              ),
            if (profile != null && !widget.isOnboarding) ...[
              _StatsCard(profile: profile),
              const SizedBox(height: 24),
            ],
            Text('Giới tính', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Gender>(
              segments: [
                for (final g in Gender.values)
                  ButtonSegment(value: g, label: Text(g.label)),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _age,
                    label: 'Tuổi',
                    validator: (v) => _validateNumber(v, 10, 100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _height,
                    label: 'Chiều cao (cm)',
                    validator: (v) => _validateNumber(v, 100, 250),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _weight,
                    label: 'Cân nặng (kg)',
                    validator: (v) => _validateNumber(v, 25, 300),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activity,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Mức độ vận động',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final a in ActivityLevel.values)
                  DropdownMenuItem(
                    value: a,
                    child: Text('${a.label} — ${a.description}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (a) => setState(() => _activity = a!),
            ),
            const SizedBox(height: 16),
            Text('Mục tiêu', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Goal>(
              segments: [
                for (final g in Goal.values)
                  ButtonSegment(value: g, label: Text(g.label)),
              ],
              selected: {_goal},
              onSelectionChanged: (s) => setState(() => _goal = s.first),
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: _targetWeight,
              label: 'Cân nặng mục tiêu (kg) — không bắt buộc',
              validator: (v) => (v ?? '').trim().isEmpty
                  ? null
                  : _validateNumber(v, 25, 300),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(widget.isOnboarding ? 'Bắt đầu' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final m = profile.macros;
    final theme = Theme.of(context);
    Widget stat(String label, String value) => Column(
          children: [
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${profile.targetCalories} kcal/ngày',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
            Text('Mục tiêu: ${profile.goal.label}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                stat('BMR', '${profile.bmr.round()}'),
                stat('TDEE', '${profile.tdee.round()}'),
                stat('BMI', profile.bmi.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 4),
            Text(profile.bmiCategory, style: theme.textTheme.bodySmall),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                stat('Đạm', '${m.protein} g'),
                stat('Tinh bột', '${m.carbs} g'),
                stat('Chất béo', '${m.fat} g'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
