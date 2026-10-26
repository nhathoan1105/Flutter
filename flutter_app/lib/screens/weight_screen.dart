import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/weight_stats.dart';

String _kg(double v) => v.toStringAsFixed(1);
String _dm(DateTime d) => '${d.day}/${d.month}';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  int _weeks = 12;

  Future<void> _addWeight(AppState state) async {
    final result = await showDialog<(DateTime, double)>(
      context: context,
      builder: (_) => _WeightDialog(initialKg: state.profile!.weightKg),
    );
    if (result == null) return;
    await state.logWeight(result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile!;
    final history = state.weightHistory;
    final weekly = weeklyAverages(history, weeks: _weeks);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cân nặng theo tuần')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addWeight(state),
        icon: const Icon(Icons.add),
        label: const Text('Ghi cân nặng'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _HeadlineStats(
            current: history.isEmpty ? profile.weightKg : history.last.kg,
            weekly: weekly,
            target: profile.targetWeightKg,
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 4, label: Text('4 tuần')),
              ButtonSegment(value: 12, label: Text('12 tuần')),
              ButtonSegment(value: 26, label: Text('6 tháng')),
            ],
            selected: {_weeks},
            onSelectionChanged: (s) => setState(() => _weeks = s.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
              child: weekly.isEmpty
                  ? const SizedBox(
                      height: 220,
                      child: Center(
                          child: Text('Chưa có dữ liệu trong khoảng này')),
                    )
                  : _WeeklyChart(
                      weekly: weekly, target: profile.targetWeightKg),
            ),
          ),
          if (weekly.length == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Cân đều mỗi tuần để thấy xu hướng — biểu đồ cần ít nhất 2 tuần.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 24),
          Text('Trung bình từng tuần', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _WeeklyTable(weekly: weekly),
          const SizedBox(height: 24),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Các lần cân (${history.length})'),
            subtitle: const Text('Vuốt sang trái để xoá'),
            children: [
              for (final h in history.reversed)
                Dismissible(
                  key: ValueKey(dateKey(h.date)),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: theme.colorScheme.errorContainer,
                    child: const Icon(Icons.delete),
                  ),
                  onDismissed: (_) => state.removeWeight(h.date),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Text('${_kg(h.kg)} kg'),
                    trailing: Text('${_dm(h.date)}/${h.date.year}'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeadlineStats extends StatelessWidget {
  const _HeadlineStats({
    required this.current,
    required this.weekly,
    required this.target,
  });

  final double current;
  final List<WeeklyWeight> weekly;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = weekly.length >= 2
        ? weekly.last.average - weekly.first.average
        : null;

    Widget stat(String label, String value, {IconData? icon}) => Expanded(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) Icon(icon, size: 18),
                    Text(value,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(label,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            stat('Hiện tại', '${_kg(current)} kg'),
            stat(
              'Thay đổi trong kỳ',
              change == null
                  ? '—'
                  : '${change > 0 ? '+' : ''}${_kg(change)} kg',
              icon: change == null || change.abs() < 0.05
                  ? null
                  : change > 0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
            ),
            stat(
              target == null ? 'Chưa đặt mục tiêu' : 'Còn tới mục tiêu',
              target == null ? '—' : '${_kg((current - target!).abs())} kg',
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.weekly, required this.target});

  final List<WeeklyWeight> weekly;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = weekly.first.weekStart;
    double weekIndex(DateTime d) => (d.difference(first).inHours / (24 * 7)).roundToDouble();

    final spots = [
      for (final w in weekly) FlSpot(weekIndex(w.weekStart), w.average),
    ];
    final values = weekly.map((w) => w.average).toList();
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    // Only pull the target into view when it's close; a far-off target would
    // flatten the line into noise.
    final showTarget = target != null &&
        target! >= minY - 5 &&
        target! <= maxY + 5;
    if (showTarget) {
      minY = math.min(minY, target!);
      maxY = math.max(maxY, target!);
    }
    minY = (minY - 1).floorToDouble();
    maxY = (maxY + 1).ceilToDouble();
    final maxX = math.max(spots.last.x, 1.0);
    final labelInterval = math.max(1.0, (maxX / 4).ceilToDouble());
    final yInterval = math.max(1.0, ((maxY - minY) / 4).ceilToDouble());
    final axisStyle = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(value.toStringAsFixed(0), style: axisStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: labelInterval,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _dm(DateTime(first.year, first.month,
                        first.day + value.round() * 7)),
                    style: axisStyle,
                  ),
                ),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (showTarget)
                HorizontalLine(
                  y: target!,
                  color: scheme.onSurfaceVariant,
                  strokeWidth: 1,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: axisStyle,
                    labelResolver: (_) => 'Mục tiêu ${_kg(target!)} kg',
                  ),
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (touched) => [
                for (final t in touched)
                  LineTooltipItem(
                    'Tuần ${_dm(weekly[t.spotIndex].weekStart)}\n'
                    '${_kg(t.y)} kg · ${weekly[t.spotIndex].count} lần cân',
                    TextStyle(color: scheme.onInverseSurface),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: scheme.primary,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: scheme.primary,
                  strokeWidth: 2,
                  strokeColor: scheme.surfaceContainerLow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTable extends StatelessWidget {
  const _WeeklyTable({required this.weekly});

  final List<WeeklyWeight> weekly;

  @override
  Widget build(BuildContext context) {
    if (weekly.isEmpty) return const Text('Chưa có dữ liệu.');
    final rows = weekly.reversed.toList();
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            ListTile(
              dense: true,
              title: Text('Tuần từ ${_dm(rows[i].weekStart)}'),
              subtitle: Text('${rows[i].count} lần cân'),
              trailing: Text(
                '${_kg(rows[i].average)} kg'
                '${i + 1 < rows.length ? '  (${_delta(rows[i].average - rows[i + 1].average)})' : ''}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
        ],
      ),
    );
  }

  String _delta(double d) => '${d >= 0 ? '+' : ''}${_kg(d)}';
}

class _WeightDialog extends StatefulWidget {
  const _WeightDialog({required this.initialKg});

  final double initialKg;

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  late final _kgController = TextEditingController(text: _kg(widget.initialKg));
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _kgController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ghi cân nặng'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _kgController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return n == null || n < 25 || n > 300
                    ? 'Nhập số từ 25–300'
                    : null;
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text('Ngày ${_dm(_date)}/${_date.year}'),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (
              _date,
              double.parse(_kgController.text.replaceAll(',', '.')),
            ));
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
