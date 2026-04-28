import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(financeProvider).goals;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas de ahorro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kBrand),
            onPressed: () => _showAddGoalSheet(context, ref),
          ),
        ],
      ),
      body: goals.isEmpty
        ? Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.track_changes_rounded, color: kMuted, size: 48),
              const SizedBox(height: 12),
              const Text('Sin metas de ahorro', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Define tus objetivos financieros', style: TextStyle(color: kMuted, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showAddGoalSheet(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva meta'),
              ),
            ]),
          ))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: goals.length,
            itemBuilder: (ctx, i) {
              final g = goals[i];
              final color = hexColor(g.color);
              return FCard(
                borderTop: color,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(g.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText), overflow: TextOverflow.ellipsis)),
                    Text('${g.progressPercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                  ]),
                  if (g.description != null && g.description!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(g.description!, style: const TextStyle(fontSize: 12, color: kMuted))),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Ahorrado: ${fmtCompact(g.currentAmount)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    Text('Meta: ${fmtCompact(g.targetAmount)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                  ]),
                  const SizedBox(height: 6),
                  FProgressBar(percent: g.progressPercent, color: color),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final input = await showDialog<String>(context: ctx, builder: (_) => _AmountDialog(goalName: g.name));
                      if (input != null) {
                        final amount = double.tryParse(input);
                        if (amount != null && amount > 0) await ref.read(financeProvider.notifier).updateGoal(g.id, g.currentAmount + amount);
                      }
                    },
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: color), color: color.withOpacity(0.08)),
                      child: Center(child: Text('+ Agregar ahorro', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ]),
              );
            },
          ),
    );
  }
}

void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _AddGoalSheet(ref: ref),
  );
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddGoalSheet({required this.ref});
  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _color = '#10b981';
  bool _loading = false;
  static const _colors = ['#10b981','#3b82f6','#8b5cf6','#f59e0b','#ef4444','#06b6d4','#f97316','#ec4899'];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 16),
        const Text('Nueva meta de ahorro', style: kTitle),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, style: const TextStyle(color: kText), decoration: const InputDecoration(labelText: 'Nombre de la meta')),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, style: const TextStyle(color: kText), decoration: const InputDecoration(labelText: 'Descripcion (opcional)')),
        const SizedBox(height: 12),
        TextField(controller: _targetCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: kText, fontSize: 16),
          decoration: const InputDecoration(labelText: 'Monto objetivo (RD\$)', prefixText: 'RD\$ ')),
        const SizedBox(height: 16),
        const Text('Color', style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, children: _colors.map((c) => GestureDetector(
          onTap: () => setState(() => _color = c),
          child: Container(width: 28, height: 28,
            decoration: BoxDecoration(color: hexColor(c), shape: BoxShape.circle, border: Border.all(color: c == _color ? Colors.white : Colors.transparent, width: 2)),
            child: c == _color ? const Icon(Icons.check, color: Colors.white, size: 14) : null),
        )).toList()),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Crear meta'),
          )),
      ])),
    );
  }
  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _targetCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre y monto son requeridos'), backgroundColor: kRed)); return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(financeProvider.notifier).addGoal({'name': _nameCtrl.text.trim(), 'description': _descCtrl.text.trim(), 'target_amount': double.parse(_targetCtrl.text), 'current_amount': 0, 'color': _color});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _AmountDialog extends StatefulWidget {
  final String goalName;
  const _AmountDialog({required this.goalName});
  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}
class _AmountDialogState extends State<_AmountDialog> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext ctx) => AlertDialog(
    backgroundColor: kSurface,
    title: Text('Agregar a "${widget.goalName}"', style: const TextStyle(fontSize: 15, color: kText)),
    content: TextField(controller: _ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: kText), decoration: const InputDecoration(labelText: 'Monto (RD\$)')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: kMuted))),
      ElevatedButton(onPressed: () => Navigator.pop(ctx, _ctrl.text), child: const Text('Guardar')),
    ],
  );
}
