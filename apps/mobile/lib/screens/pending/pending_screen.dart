import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../models/models.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(financeProvider).pendingItems;
    final now   = DateTime.now();

    final overdue   = items.where((p) => p.status != 'collected' && p.dueDate.isBefore(now)).length;
    final upcoming  = items.where((p) => p.status != 'collected' && !p.dueDate.isBefore(now) && p.dueDate.difference(now).inDays <= 7).length;
    final onTime    = items.where((p) => p.status != 'collected' && p.dueDate.difference(now).inDays > 7).length;
    final collected = items.where((p) => p.status == 'collected').length;
    final total     = items.where((p) => p.status != 'collected').fold(0.0, (s, p) => s + p.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Por cobrar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kBrand),
            onPressed: () => _showAddSheet(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _KpiCard(label: 'Vencidos',   value: '$overdue',   color: kRed),
            const SizedBox(width: 8),
            _KpiCard(label: 'Por vencer', value: '$upcoming',  color: kAmber),
            const SizedBox(width: 8),
            _KpiCard(label: 'A tiempo',   value: '$onTime',    color: kBlue),
            const SizedBox(width: 8),
            _KpiCard(label: 'Cobrados',   value: '$collected', color: kBrand),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.attach_money_rounded, color: kBrand, size: 18),
                  const SizedBox(width: 8),
                  const Text('Total por cobrar:', style: TextStyle(color: kTextSub, fontSize: 13)),
                ]),
                Text(fmtCurrency(total),
                  style: const TextStyle(color: kBrand, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                const Icon(Icons.access_time_rounded, color: kMuted, size: 48),
                const SizedBox(height: 12),
                const Text('Sin cobros pendientes',
                  style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Registra facturas y deudas por cobrar',
                  style: TextStyle(color: kMuted, fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showAddSheet(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nuevo pendiente'),
                ),
              ]),
            ))
          else
            // FIX: ya no se pasa ref como parámetro
            ...items.map((p) => _PendingCard(item: p, now: now)),
        ],
      ),
    );
  }
}

// FIX: ConsumerWidget en vez de StatelessWidget con ref inyectado
class _PendingCard extends ConsumerWidget {
  final PendingItem item;
  final DateTime now;
  const _PendingCard({required this.item, required this.now, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollected = item.status == 'collected';
    final isOverdue   = !isCollected && item.dueDate.isBefore(now);
    final isUpcoming  = !isCollected && !isOverdue && item.dueDate.difference(now).inDays <= 7;

    final statusColor = isCollected ? kBrand : isOverdue ? kRed : isUpcoming ? kAmber : kBlue;
    final statusLabel = isCollected ? 'Cobrado' : isOverdue ? 'Vencido' : isUpcoming ? 'Por vencer' : 'Pendiente';
    final statusIcon  = isCollected
        ? Icons.check_circle_outline_rounded
        : isOverdue
            ? Icons.error_outline_rounded
            : isUpcoming
                ? Icons.warning_amber_rounded
                : Icons.access_time_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FCard(
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.debtorName, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isCollected ? kMuted : kText,
                  decoration: isCollected ? TextDecoration.lineThrough : null,
                )),
                const SizedBox(height: 2),
                Text(item.description, style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 4),
                Text('Vence ${fmtDate(item.dueDate)}', style: TextStyle(fontSize: 11, color: statusColor)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 11, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmtCurrency(item.amount), style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isCollected ? kMuted : kText,
              )),
              const SizedBox(height: 8),
              if (!isCollected)
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: kSurface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => _CollectSheet(item: item),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kBrand.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBrand.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline_rounded, color: kBrand, size: 13),
                      SizedBox(width: 4),
                      Text('Cobrar', style: TextStyle(
                        color: kBrand, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              const SizedBox(height: 6),
              Builder(
                builder: (btnContext) => GestureDetector(
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: btnContext,
                      builder: (_) => AlertDialog(
                        backgroundColor: kSurface,
                        title: const Text('Eliminar', style: TextStyle(color: kText, fontSize: 15)),
                        content: const Text('Esta accion no se puede deshacer.',
                          style: TextStyle(color: kMuted, fontSize: 13)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(_, false),
                            child: const Text('Cancelar', style: TextStyle(color: kMuted))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: kRed),
                            onPressed: () => Navigator.pop(_, true),
                            child: const Text('Eliminar')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(financeProvider.notifier).deletePendingItem(item.id);
                    }
                  },
                  child: const Icon(Icons.delete_outline_rounded, color: kMuted, size: 18),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// FIX: ConsumerStatefulWidget sin parámetro ref, con campo monto editable
class _CollectSheet extends ConsumerStatefulWidget {
  final PendingItem item;
  const _CollectSheet({required this.item});
  @override
  ConsumerState<_CollectSheet> createState() => _CollectSheetState();
}

class _CollectSheetState extends ConsumerState<_CollectSheet> {
  late String? selectedId;
  bool showDropdown = false;
  late TextEditingController amountCtrl;

  @override
  void initState() {
    super.initState();
    final accounts = ref.read(financeProvider).accounts
        .where((a) => a.type != 'deuda' && a.type != 'prestamo' && a.isActive)
        .toList();
    selectedId = accounts.isNotEmpty ? accounts.first.id : null;
    amountCtrl = TextEditingController(text: widget.item.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.read(financeProvider).accounts
        .where((a) => a.type != 'deuda' && a.type != 'prestamo' && a.isActive)
        .toList();
    final selectedAccount = accounts.isNotEmpty
        ? accounts.firstWhere((a) => a.id == selectedId, orElse: () => accounts.first)
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          const Text('Registrar cobro', style: kTitle),
          const SizedBox(height: 4),
          Text('${widget.item.debtorName} · ${fmtCurrency(widget.item.amount)}',
            style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 20),
          const Text('Cuenta destino', style: TextStyle(color: kTextSub, fontSize: 13)),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            const Text('No hay cuentas disponibles', style: TextStyle(color: kMuted, fontSize: 13))
          else ...[
            GestureDetector(
              onTap: () => setState(() => showDropdown = !showDropdown),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: showDropdown ? kBrand.withOpacity(0.4) : kBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(selectedAccount?.name ?? '',
                        style: const TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(fmtCurrency(selectedAccount?.balance ?? 0),
                        style: const TextStyle(color: kMuted, fontSize: 11)),
                    ]),
                    Icon(showDropdown
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                      color: kMuted, size: 20),
                  ],
                ),
              ),
            ),
            if (showDropdown) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  children: accounts.map((a) => GestureDetector(
                    onTap: () => setState(() {
                      selectedId = a.id;
                      showDropdown = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: selectedId == a.id ? kBrand.withOpacity(0.08) : Colors.transparent,
                        border: Border(bottom: BorderSide(
                          color: a == accounts.last ? Colors.transparent : kBorder,
                          width: 0.5,
                        )),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a.name, style: TextStyle(
                            color: selectedId == a.id ? kBrand : kText,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(fmtCurrency(a.balance),
                            style: const TextStyle(color: kMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          const Text('Monto cobrado', style: TextStyle(color: kTextSub, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: 'RD\$ ',
              prefixStyle: const TextStyle(color: kMuted, fontSize: 14),
              hintText: '0.00',
              hintStyle: const TextStyle(color: kMuted),
              suffixIcon: GestureDetector(
                onTap: () => setState(() =>
                  amountCtrl.text = widget.item.amount.toStringAsFixed(2)),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text('Max', style: TextStyle(
                    color: kBrand, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: 6),
          Text('Total pendiente: ${fmtCurrency(widget.item.amount)}',
            style: const TextStyle(color: kMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedId == null ? null : () async {
                final paid = double.tryParse(amountCtrl.text) ?? 0;
                if (paid <= 0) return;
                final accountId = selectedId!;
                Navigator.pop(context);
                await ref.read(financeProvider.notifier)
                    .markPendingCollected(widget.item.id, accountId, paid);
              },
              child: const Text('Confirmar cobro'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: kSurface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: kMuted), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// FIX: quitado parámetro ref
void _showAddSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _AddPendingSheet(),
  );
}

class _AddPendingSheet extends ConsumerStatefulWidget {
  const _AddPendingSheet();
  @override
  ConsumerState<_AddPendingSheet> createState() => _AddPendingSheetState();
}

class _AddPendingSheetState extends ConsumerState<_AddPendingSheet> {
  final _nameCtrl   = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          const Text('Nuevo pendiente', style: kTitle),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, style: const TextStyle(color: kText),
            decoration: const InputDecoration(labelText: 'Nombre del deudor')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, style: const TextStyle(color: kText),
            decoration: const InputDecoration(labelText: 'Descripcion')),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: kText, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Monto (RD\$)', prefixText: 'RD\$ ')),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
                color: kSurface2,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Vence: ${fmtDate(_dueDate)}',
                  style: const TextStyle(color: kText, fontSize: 14)),
                const Icon(Icons.calendar_today_outlined, color: kMuted, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Registrar pendiente'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y monto son requeridos'), backgroundColor: kRed));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(financeProvider.notifier).addPendingItem({
        'debtor_name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'amount':      double.parse(_amountCtrl.text),
        'due_date':    _dueDate.toIso8601String().split('T')[0],
        'status':      'pending',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}