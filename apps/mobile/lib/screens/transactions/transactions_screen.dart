// transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../models/models.dart';
import '../../widgets/modals/transfer_modal.dart';

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
      if (_filter == 'all') return true;
      if (_filter == 'income'  && t.type != 'income')  return false;
      if (_filter == 'expense' && t.type != 'expense') return false;
      if (_filter == 'transfer' && t.type != 'transfer') return false;
      if (_searchCtrl.text.isNotEmpty) {
        final q = _searchCtrl.text.toLowerCase();
        return t.detail.toLowerCase().contains(q) ||
          (t.category?.name ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kBrand),
            onSelected: (val) {
              if (val == 'transfer') {
                showDialog(context: context, builder: (_) => const TransferModal());
              } else if (val == 'income' || val == 'expense') {
                _showAddTransactionSheet(context, ref, val);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'income', child: Row(children: [
                Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 12),
                Text('Ingreso', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
              ])),
              const PopupMenuItem(value: 'expense', child: Row(children: [
                Icon(Icons.arrow_downward_rounded, color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 12),
                Text('Egreso', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
              ])),
              const PopupMenuItem(value: 'transfer', child: Row(children: [
                Icon(Icons.compare_arrows_rounded, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 12),
                Text('Transferencia', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
              ])),
            ],
          )
        ],
      ),
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
              Row(children: ['all', 'income', 'expense', 'transfer'].map((f) => Expanded(
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
                      {
                        'all': 'Todos',
                        'income': 'Ingresos',
                        'expense': 'Egresos',
                        'transfer': 'Transferencias'
                      }[f]!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _filter == f ? kBrand : kMuted
                      ),
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
              _SummaryChip(
                '${txs.where((t) => t.type == 'income').length} ingresos',
                fmtCompact(txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount)),
                kBrand,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                '${txs.where((t) => t.type == 'expense').length} egresos',
                fmtCompact(txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount)),
                kRed,
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
            overflow: TextOverflow.ellipsis),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}
class _TxListTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onDelete;
  const _TxListTile(this.tx, {required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (tx.type == 'transfer') {
        return tx.amount > 0 ? kBrand : const Color(0xFFF59E0B);
      }
      return typeColor(tx.type);
    }

    IconData getIcon() {
      if (tx.type == 'transfer') {
        return tx.amount > 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
      }
      return tx.type == 'income' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    }

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: getColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(getIcon(), color: getColor(), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.detail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText),
              overflow: TextOverflow.ellipsis),
            Text('${tx.type == 'transfer' ? '⇄ Transferencia' : (tx.category?.name ?? '')} · ${tx.account?.name ?? ''}',
              style: const TextStyle(fontSize: 11, color: kMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${tx.amount >= 0 ? '+' : ''}${fmtCompact(tx.amount)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: getColor())),
            Text(fmtDate(tx.transactionDate), style: const TextStyle(fontSize: 10, color: kMuted)),
          ]),
        ]),
      ),
    );
  }
}

Color typeColor(String type) {
  switch (type) {
    case 'income': return kBrand;
    case 'expense': return kRed;
    case 'transfer': return kBrand;
    default: return kMuted;
  }
}

String typeSign(String type) {
  switch (type) {
    case 'income': return '+';
    case 'expense': return '-';
    case 'transfer': return '';
    default: return '';
  }
}

void _showAddTransactionSheet(BuildContext context, WidgetRef ref, [String type = 'income']) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AddTxSheet(ref: ref, initialType: type),
  );
}

class _AddTxSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String initialType;
  const _AddTxSheet({required this.ref, this.initialType = 'income'});
  @override
  ConsumerState<_AddTxSheet> createState() => _AddTxSheetState();
}

class _AddTxSheetState extends ConsumerState<_AddTxSheet> {
  late String _type;
  final _detailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final cats = state.categories.where((c) =>
      _type == 'income' ? c.movementType == 1 : c.movementType == 2).toList();
    final accounts = state.accounts.where((a) => a.isActive).toList();
    final accent = _type == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFF1E2A3A), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          const Text('Nuevo movimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE2E8F0))),
          const SizedBox(height: 16),
          Row(children: ['income', 'expense'].map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _type = t; _categoryId = null; }),
              child: Container(
                margin: EdgeInsets.only(right: t == 'income' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _type == t ? (t == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : const Color(0xFF1E2A3A)),
                  color: _type == t ? (t == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1) : Colors.transparent,
                ),
                child: Center(child: Text(
                  t == 'income' ? '↑ Ingreso' : '↓ Egreso',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _type == t ? (t == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : const Color(0xFF4A6B8A)),
                )),
              ),
            ),
          )).toList()),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 18, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(labelText: 'Monto (RD\$)', prefixText: 'RD\$ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailCtrl,
            style: const TextStyle(color: Color(0xFFE2E8F0)),
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categoryId,
            dropdownColor: const Color(0xFF111827),
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: cats.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text('${c.icon} ${c.name}'),
            )).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _accountId,
            dropdownColor: const Color(0xFF111827),
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
            decoration: const InputDecoration(labelText: 'Cuenta / Almacén'),
            items: accounts.map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.name),
            )).toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: _loading ? null : _submit,
              child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Registrar movimiento'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _categoryId == null || _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: Color(0xFFEF4444)));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(financeProvider.notifier).addTransaction({
        'account_id':       _accountId,
        'category_id':      _categoryId,
        'amount': _type == 'expense'
    ? -double.parse(_amountCtrl.text)
    : double.parse(_amountCtrl.text),
        'detail':           _detailCtrl.text,
        'transaction_date': _date.toIso8601String().split('T')[0],
        'type':             _type,
        'is_recurring':     false,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e'), backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
