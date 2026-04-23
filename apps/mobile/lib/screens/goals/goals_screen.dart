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
      appBar: AppBar(title: const Text('Metas de ahorro')),
      body: goals.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.track_changes_rounded, color: kMuted, size: 48),
            const SizedBox(height: 12),
            const Text('Sin metas', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Configura tus objetivos de ahorro desde la web', style: TextStyle(color: kMuted, fontSize: 12)),
          ]))
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
                    Text(g.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                    Text('${g.progressPercent.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                  ]),
                  if (g.description != null && g.description!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2),
                      child: Text(g.description!, style: const TextStyle(fontSize: 12, color: kMuted))),
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
                      final input = await showDialog<String>(
                        context: ctx,
                        builder: (_) => _AmountDialog(goalName: g.name),
                      );
                      if (input != null) {
                        final amount = double.tryParse(input);
                        if (amount != null && amount > 0) {
                          await ref.read(financeProvider.notifier).updateGoal(g.id, g.currentAmount + amount);
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color),
                        color: color.withOpacity(0.08),
                      ),
                      child: Center(child: Text('+ Agregar ahorro',
                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ]),
              );
            },
          ),
    );
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
    content: TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: kText),
      decoration: const InputDecoration(labelText: 'Monto (RD\$)'),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: kMuted))),
      ElevatedButton(onPressed: () => Navigator.pop(ctx, _ctrl.text), child: const Text('Guardar')),
    ],
  );
}
