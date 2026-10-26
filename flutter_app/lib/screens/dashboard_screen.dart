import 'package:flutter/material.dart';

import '../services/app_state.dart';
import 'add_food_sheet.dart';
import 'water_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _dateLabel(AppState state) {
    if (state.isViewingToday) return 'Hôm nay';
    final d = state.selectedDate;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile!;
    final log = state.today;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => state.shiftDate(-1),
            ),
            Text(_dateLabel(state)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: state.isViewingToday ? null : () => state.shiftDate(1),
            ),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AddFoodSheet(state: state),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Thêm món ăn'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _SummaryCard(
            target: profile.targetCalories,
            consumed: log.consumed,
            burned: log.burned,
          ),
          const SizedBox(height: 12),
          const WaterCard(),
          const SizedBox(height: 16),
          Text('Món đã ăn', style: theme.textTheme.titleMedium),
          if (log.foods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Chưa có món nào. Nhấn "Thêm món ăn" để bắt đầu.'),
            ),
          for (final f in log.foods)
            Dismissible(
              key: ValueKey(f.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: theme.colorScheme.errorContainer,
                child: const Icon(Icons.delete),
              ),
              onDismissed: (_) => state.removeFood(f.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant),
                title: Text(f.name),
                subtitle: Text(
                    '${_fmtServings(f.servings)} phần × ${f.calories} kcal'),
                trailing: Text('${f.totalCalories} kcal',
                    style: theme.textTheme.titleSmall),
              ),
            ),
          if (log.exercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Đã tập', style: theme.textTheme.titleMedium),
            for (final e in log.exercises)
              Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: theme.colorScheme.errorContainer,
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => state.removeExercise(e.id),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_fire_department),
                  title: Text(e.name),
                  subtitle: Text('${e.minutes} phút'),
                  trailing: Text('−${e.caloriesBurned} kcal',
                      style: theme.textTheme.titleSmall),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _fmtServings(double s) =>
      s == s.roundToDouble() ? s.toStringAsFixed(0) : s.toString();
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.target,
    required this.consumed,
    required this.burned,
  });

  final int target;
  final int consumed;
  final int burned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = target - consumed + burned;
    final over = remaining < 0;
    final progress = (consumed - burned) / target;
    final color = over ? theme.colorScheme.error : theme.colorScheme.primary;

    Widget stat(String label, int value, IconData icon) => Column(
          children: [
            Icon(icon, size: 20),
            Text('$value',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 12,
                    color: color,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${remaining.abs()}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold, color: color)),
                        Text(over ? 'kcal vượt mức' : 'kcal còn lại'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                stat('Mục tiêu', target, Icons.flag),
                stat('Đã ăn', consumed, Icons.restaurant),
                stat('Đã đốt', burned, Icons.local_fire_department),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
