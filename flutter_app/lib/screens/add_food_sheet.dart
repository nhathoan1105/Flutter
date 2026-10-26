import 'package:flutter/material.dart';

import '../data/food_database.dart';
import '../services/app_state.dart';

class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({super.key, required this.state});

  final AppState state;

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  String _query = '';

  List<FoodItem> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return foodDatabase;
    return foodDatabase.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _pickServings(FoodItem item) async {
    final servings = await showDialog<double>(
      context: context,
      builder: (_) => _ServingsDialog(item: item),
    );
    if (servings == null || !mounted) return;
    await widget.state.addFood(item.name, item.calories, servings);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addCustom() async {
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => _CustomFoodDialog(initialName: _query.trim()),
    );
    if (result == null || !mounted) return;
    await widget.state.addFood(result.$1, result.$2, 1);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm món ăn (phở, cơm tấm, trứng...)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Tự nhập món khác'),
              subtitle: const Text('Nhập tên và số calo'),
              onTap: _addCustom,
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final f = results[i];
                  return ListTile(
                    title: Text(f.name),
                    subtitle: Text('${f.serving} · ${f.category}'),
                    trailing: Text('${f.calories} kcal'),
                    onTap: () => _pickServings(f),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServingsDialog extends StatefulWidget {
  const _ServingsDialog({required this.item});

  final FoodItem item;

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  double _servings = 1;

  @override
  Widget build(BuildContext context) {
    final total = (widget.item.calories * _servings).round();
    return AlertDialog(
      title: Text(widget.item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('1 phần = ${widget.item.serving} (${widget.item.calories} kcal)'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _servings > 0.5
                    ? () => setState(() => _servings -= 0.5)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_servings phần',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => _servings += 0.5),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tổng: $total kcal'),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _servings),
            child: const Text('Thêm')),
      ],
    );
  }
}

class _CustomFoodDialog extends StatefulWidget {
  const _CustomFoodDialog({required this.initialName});

  final String initialName;

  @override
  State<_CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<_CustomFoodDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  final _calories = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Món tự nhập'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên món'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nhập tên món' : null,
            ),
            TextFormField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calo (kcal)'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 || n > 5000
                    ? 'Nhập số từ 1–5000'
                    : null;
              },
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
            Navigator.pop(
                context, (_name.text.trim(), int.parse(_calories.text)));
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
