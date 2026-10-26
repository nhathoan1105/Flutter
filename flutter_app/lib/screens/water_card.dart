import 'package:flutter/material.dart';

import '../models/water.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';

String _liters(int ml) => '${(ml / 1000).toStringAsFixed(1)} L';

class WaterCard extends StatelessWidget {
  const WaterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final log = state.today;
    final settings = state.waterSettings;
    final goal = state.waterGoal;
    final drunk = log.waterMl;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = state.isViewingToday &&
        drunk < goal &&
        isWaterOverdue(settings, DateTime.now(), log.lastDrink);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Nước: ${_liters(drunk)} / ${_liters(goal)}',
                      style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Cài đặt nhắc uống nước',
                  icon: Icon(settings.remindersEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_none),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _WaterSettingsSheet(state: state),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (drunk / goal).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              drunk >= goal
                  ? 'Đã đủ nước hôm nay 🎉'
                  : 'Còn khoảng ${((goal - drunk) / settings.glassMl).ceil()} '
                      'ly ${settings.glassMl} ml',
              style: theme.textTheme.bodySmall,
            ),
            if (overdue)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  log.lastDrink == null
                      ? 'Bạn chưa uống nước hôm nay — uống một ly nhé!'
                      : 'Đã hơn ${settings.intervalHours} giờ bạn chưa uống nước.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => state.addWater(settings.glassMl),
                  icon: const Icon(Icons.local_drink),
                  label: Text('+${settings.glassMl} ml'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: log.water.isEmpty ? null : state.undoWater,
                  child: const Text('Hoàn tác'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterSettingsSheet extends StatefulWidget {
  const _WaterSettingsSheet({required this.state});

  final AppState state;

  @override
  State<_WaterSettingsSheet> createState() => _WaterSettingsSheetState();
}

class _WaterSettingsSheetState extends State<_WaterSettingsSheet> {
  late WaterSettings _s = widget.state.waterSettings;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    var settings = _s;
    String? message;
    if (settings.remindersEnabled && NotificationService.isSupported) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        settings = settings.copyWith(remindersEnabled: false);
        message = 'Bạn chưa cấp quyền thông báo nên chưa thể bật nhắc.';
      }
    }
    try {
      await widget.state.saveWaterSettings(settings);
    } catch (e) {
      message = 'Không thể đặt lịch nhắc: $e';
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(message ??
          (settings.remindersEnabled
              ? 'Sẽ nhắc lúc ${settings.reminderHours.map((h) => '${h}h').join(', ')}'
              : 'Đã lưu cài đặt')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = _s.reminderHours;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nhắc uống nước', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bật thông báo nhắc'),
            subtitle: NotificationService.isSupported
                ? null
                : const Text('Thông báo chỉ hỗ trợ trên Android. Trên nền tảng '
                    'này app sẽ nhắc ngay trên màn Hôm nay.'),
            value: _s.remindersEnabled,
            onChanged: NotificationService.isSupported
                ? (v) => setState(() => _s = _s.copyWith(remindersEnabled: v))
                : null,
          ),
          const SizedBox(height: 8),
          Text('Khung giờ: ${_s.startHour}h – ${_s.endHour}h',
              style: theme.textTheme.titleSmall),
          RangeSlider(
            values: RangeValues(_s.startHour.toDouble(), _s.endHour.toDouble()),
            min: 5,
            max: 23,
            divisions: 18,
            labels: RangeLabels('${_s.startHour}h', '${_s.endHour}h'),
            onChanged: (v) {
              if (v.end - v.start < 1) return;
              setState(() => _s = _s.copyWith(
                  startHour: v.start.round(), endHour: v.end.round()));
            },
          ),
          Text('Nhắc mỗi', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1 giờ')),
              ButtonSegment(value: 2, label: Text('2 giờ')),
              ButtonSegment(value: 3, label: Text('3 giờ')),
            ],
            selected: {_s.intervalHours},
            onSelectionChanged: (v) =>
                setState(() => _s = _s.copyWith(intervalHours: v.first)),
          ),
          const SizedBox(height: 16),
          Text('Cỡ ly', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 200, label: Text('200 ml')),
              ButtonSegment(value: 250, label: Text('250 ml')),
              ButtonSegment(value: 350, label: Text('350 ml')),
              ButtonSegment(value: 500, label: Text('500 ml')),
            ],
            selected: {_s.glassMl},
            onSelectionChanged: (v) =>
                setState(() => _s = _s.copyWith(glassMl: v.first)),
          ),
          const SizedBox(height: 16),
          Text(
            '${hours.length} lần nhắc/ngày: '
            '${hours.map((h) => '${h}h').join(', ')}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Lưu'),
            ),
          ),
        ],
      ),
    );
  }
}
