// transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../models/models.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final txs = state.transactions.where((t) {
      if (_filter == 'income'  && t.type != 'income')  return false;
      if (_filter == 'expense' && t.type != 'expense') return false;
      if (_searchCtrl.text.isNotEmpty) {
        final q = _searchCtrl.text.toLowerCase();
        return t.detail.toLowerCase().contains(q) ||
          (t.category?.name ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kBrand),
            onPressed: () {},
          )
        ]),
      body: Column(
        children: [
          // Search & filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: kText, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Buscar movimiento...',
                  prefixIcon: Icon(Icons.search_rounded, color: kMuted, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: ['all', 'income', 'expense'].map((f) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _filter == f ? kBrand.withOpacity(0.15) : Colors.transparent,
                      border: Border.all(color: _filter == f ? kBrand : kBorder),
                    ),
                    child: Center(child: Text(
                      {'all': 'Todos', 'income': 'Ingresos', 'expense': 'Egresos'}[f]!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: _filter == f ? kBrand : kMuted),
                    )),
                  ),
                ),
              )).toList()),
            ]),
          ),
          const SizedBox(height: 12),

          // Summary row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _SummaryChip('${txs.where((t) => t.type == 'income').length} ingresos',
                fmtCompact(txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount)), kBrand),
              const SizedBox(width: 8),
              _SummaryChip('${txs.where((t) => t.type == 'expense').length} egresos',
                fmtCompact(txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount)), kRed),
            ]),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: txs.isEmpty
              ? const Center(child: Text('Sin movimientos', style: TextStyle(color: kMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: txs.length,
                  itemBuilder: (ctx, i) => _TxListTile(txs[i], onDelete: () async {
                    await ref.read(financeProvider.notifier).deleteTransaction(txs[i].id);
                  }),
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

class _TxListTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onDelete;
  const _TxListTile(this.tx, {required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = typeColor(tx.type);
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: kRed.withOpacity(0.15),
        child: const Icon(Icons.delete_outline_rounded, color: kRed),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return true;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(tx.type == 'income' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.detail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText),
              overflow: TextOverflow.ellipsis),
            Text('${tx.category?.name ?? ''} · ${tx.account?.name ?? ''}',
              style: const TextStyle(fontSize: 11, color: kMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${typeSign(tx.type)}${fmtCompact(tx.amount)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(fmtDate(tx.transactionDate), style: const TextStyle(fontSize: 10, color: kMuted)),
          ]),
        ]),
      ),
    );
  }
}
