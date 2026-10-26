import 'package:flutter/material.dart';

import '../data/exercise_database.dart';
import '../services/app_state.dart';
import '../services/recommendation.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  Future<void> _logExercise(
      BuildContext context, AppState state, Exercise exercise, int minutes) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _LogExerciseDialog(
        exercise: exercise,
        weightKg: state.profile!.weightKg,
        initialMinutes: minutes,
      ),
    );
    if (result == null) return;
    await state.addExercise(
      exercise.name,
      result,
      exercise.caloriesFor(result, state.profile!.weightKg),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ghi: ${exercise.name} $result phút')));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile!;
    final rec = buildRecommendation(profile, state.today);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Đề xuất bài tập')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(rec.headline,
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer)),
                      ),
                    ],
                  ),
                  for (final note in rec.notes) ...[
                    const SizedBox(height: 8),
                    Text('• $note',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            rec.burnTarget > 0
                ? 'Chọn một bài để đốt ~${rec.burnTarget} kcal'
                : 'Bài tập phù hợp với bạn',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final s in rec.suggestions)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(s.exercise.icon)),
                title: Text(s.exercise.name),
                subtitle: Text(
                    '${s.minutes} phút · ~${s.calories} kcal · '
                    '${s.exercise.type.label} · ${s.exercise.intensity.label}\n'
                    '${s.exercise.tip}'),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Ghi lại đã tập',
                  icon: const Icon(Icons.add_task),
                  onPressed: () =>
                      _logExercise(context, state, s.exercise, s.minutes),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Lịch tập tuần gợi ý', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final day in rec.weeklyPlan)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.calendar_today, size: 18),
                      title: Text(day),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Tất cả bài tập'),
            subtitle: const Text('Calo đốt trong 30 phút theo cân nặng của bạn'),
            children: [
              for (final e in exerciseDatabase)
                ListTile(
                  leading: Icon(e.icon),
                  title: Text(e.name),
                  subtitle: Text(
                      '~${e.caloriesFor(30, profile.weightKg)} kcal / 30 phút'),
                  trailing: const Icon(Icons.add_task),
                  onTap: () => _logExercise(context, state, e, 30),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Lưu ý: số liệu chỉ mang tính tham khảo. Hãy hỏi ý kiến bác sĩ '
            'nếu bạn có bệnh lý tim mạch, xương khớp hoặc đang mang thai.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LogExerciseDialog extends StatefulWidget {
  const _LogExerciseDialog({
    required this.exercise,
    required this.weightKg,
    required this.initialMinutes,
  });

  final Exercise exercise;
  final double weightKg;
  final int initialMinutes;

  @override
  State<_LogExerciseDialog> createState() => _LogExerciseDialogState();
}

class _LogExerciseDialogState extends State<_LogExerciseDialog> {
  // Snap to the slider's 5-minute steps.
  late double _minutes =
      ((widget.initialMinutes / 5).round() * 5).clamp(5, 120).toDouble();

  @override
  Widget build(BuildContext context) {
    final minutes = _minutes.round();
    return AlertDialog(
      title: Text(widget.exercise.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$minutes phút',
              style: Theme.of(context).textTheme.headlineSmall),
          Slider(
            value: _minutes,
            min: 5,
            max: 120,
            divisions: 23,
            label: '$minutes',
            onChanged: (v) => setState(() => _minutes = v),
          ),
          Text(
              '≈ ${widget.exercise.caloriesFor(minutes, widget.weightKg)} kcal'),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        FilledButton(
            onPressed: () => Navigator.pop(context, minutes),
            child: const Text('Ghi lại')),
      ],
    );
  }
}
