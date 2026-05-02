import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../models/models.dart';

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});
  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingDebits());
  }

  Future<void> _checkPendingDebits() async {
    final state = ref.read(financeProvider);
    final now = DateTime.now();
    for (final rp in state.recurringPayments) {
      if (!rp.isAuto) continue;
      if (rp.autoDebitAt != null && now.isAfter(rp.autoDebitAt!)) {
        await ref.read(financeProvider.notifier).executeRecurringPayment(rp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final items = state.recurringPayments;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text('Pagos Recurrentes',
          style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kBrand),
            onPressed: () => _showAddModal(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrand))
          : items.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _RecurringTile(
                    rp: items[i],
                    onEdit: () => _showAddModal(context, rp: items[i]),
                    onDelete: () => _confirmDelete(context, items[i]),
                    onExecute: () => _confirmExecute(context, items[i]),
                    onSchedule: () => ref.read(financeProvider.notifier).scheduleAutoDebit(items[i].id),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.repeat_rounded, color: kMuted, size: 56),
      const SizedBox(height: 16),
      const Text('Sin pagos recurrentes', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Agrega pagos fijos mensuales\npara gestionarlos automaticamente',
        style: TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => _showAddModal(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Agregar pago', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: kBrand,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    ]),
  );

  Future<void> _confirmDelete(BuildContext context, RecurringPayment rp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Eliminar', style: TextStyle(color: kText)),
        content: Text('Eliminar "${rp.name}"?', style: const TextStyle(color: kMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: kMuted))),
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true && mounted) ref.read(financeProvider.notifier).deleteRecurringPayment(rp.id);
  }

  Future<void> _confirmExecute(BuildContext context, RecurringPayment rp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Ejecutar pago', style: TextStyle(color: kText)),
        content: Text('Debitar ${fmtCompact(rp.amount)} de ${rp.account?.name ?? rp.accountId} ahora?',
          style: const TextStyle(color: kMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: kMuted))),
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Ejecutar', style: TextStyle(color: kBrand))),
        ],
      ),
    );
    if (ok == true && mounted) ref.read(financeProvider.notifier).executeRecurringPayment(rp);
  }

  void _showAddModal(BuildContext context, {RecurringPayment? rp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RecurringModal(existing: rp),
    );
  }
}

// --- Tile -------------------------------------------------------------------
class _RecurringTile extends StatelessWidget {
  final RecurringPayment rp;
  final VoidCallback onEdit, onDelete, onExecute, onSchedule;
  const _RecurringTile({required this.rp, required this.onEdit,
    required this.onDelete, required this.onExecute, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    final isPending = rp.isPending;
    final inWindow  = rp.isInEditWindow;
    final timeLeft  = rp.timeLeftInWindow;
    final hours     = timeLeft.inHours;
    final minutes   = timeLeft.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPending ? kRed.withOpacity(0.4) : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: kBrand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.repeat_rounded, color: kBrand, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rp.name, style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Dia ${rp.dayOfMonth} de cada mes',
              style: const TextStyle(color: kMuted, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtCompact(rp.amount),
              style: const TextStyle(color: kRed, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(rp.account?.name ?? '', style: const TextStyle(color: kMuted, fontSize: 10)),
          ]),
        ]),

        if (isPending) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kRed.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: kRed, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(
                inWindow
                  ? 'Debito automatico en ${hours}h ${minutes}m — puedes editar antes'
                  : 'Pago pendiente para hoy',
                style: const TextStyle(color: kRed, fontSize: 11))),
            ]),
          ),
        ],

        const SizedBox(height: 10),
        Row(children: [
          if (rp.isAuto && !inWindow && isPending)
            Expanded(child: _btn('Activar (5h)', kBrand, onSchedule)),
          if (!rp.isAuto || !isPending)
            Expanded(child: _btn('Ejecutar ahora', kBrand, onExecute)),
          const SizedBox(width: 8),
          Expanded(child: _btn('Editar', kSurface2, onEdit, textColor: kText)),
          const SizedBox(width: 8),
          _iconBtn(Icons.delete_outline_rounded, kRed, onDelete),
        ]),
      ]),
    );
  }

  Widget _btn(String label, Color bg, VoidCallback onTap, {Color textColor = Colors.white}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor))),
      ),
    );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
}

// --- Modal ------------------------------------------------------------------
class _RecurringModal extends ConsumerStatefulWidget {
  final RecurringPayment? existing;
  const _RecurringModal({this.existing});
  @override
  ConsumerState<_RecurringModal> createState() => _RecurringModalState();
}

class _RecurringModalState extends ConsumerState<_RecurringModal> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _accountId;
  String? _categoryId;
  int _day = 1;
  bool _isAuto = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final rp = widget.existing!;
      _nameCtrl.text   = rp.name;
      _amountCtrl.text = rp.amount.toString();
      _accountId       = rp.accountId;
      _categoryId      = rp.categoryId;
      _day             = rp.dayOfMonth;
      _isAuto          = rp.isAuto;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty || _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: kRed));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _loading = true);
    try {
      final nextDate = DateTime(DateTime.now().year, DateTime.now().month, _day);
      final data = {
        'name':              _nameCtrl.text.trim(),
        'amount':            amount,
        'account_id':        _accountId,
        'category_id':       _categoryId,
        'day_of_month':      _day,
        'next_payment_date': nextDate.toIso8601String().split('T')[0],
        'is_auto':           _isAuto,
        'status':            'active',
      };
      if (widget.existing == null) {
        await ref.read(financeProvider.notifier).addRecurringPayment(data);
      } else {
        await ref.read(financeProvider.notifier).updateRecurringPayment(widget.existing!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(financeProvider);
    final accounts = state.accounts.where((a) => a.type != 'deuda' && a.type != 'prestamo').toList();
    final cats     = state.categories.where((c) => c.movementType == 2).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.existing == null ? 'Nuevo pago recurrente' : 'Editar pago',
              style: const TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: kMuted),
              onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),

          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: kText),
            decoration: const InputDecoration(labelText: 'Nombre del pago'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: kText),
            decoration: const InputDecoration(labelText: 'Monto (RD\$)', prefixText: 'RD\$ '),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _accountId,
            dropdownColor: kSurface,
            style: const TextStyle(color: kText, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Cuenta a debitar'),
            items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _categoryId,
            dropdownColor: kSurface,
            style: const TextStyle(color: kText, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Categoria (opcional)'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sin categoria')),
              ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),

          Row(children: [
            const Text('Dia del mes:', style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _day.toDouble(),
                min: 1, max: 31,
                divisions: 30,
                activeColor: kBrand,
                label: 'Dia $_day',
                onChanged: (v) => setState(() => _day = v.round()),
              ),
            ),
            Text('$_day', style: const TextStyle(color: kText, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Debito automatico', style: TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Se ejecuta con 5h para editar', style: TextStyle(color: kMuted, fontSize: 11)),
            ]),
            Switch(value: _isAuto, onChanged: (v) => setState(() => _isAuto = v), activeColor: kBrand),
          ]),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrand,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _loading
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(widget.existing == null ? 'Guardar pago' : 'Actualizar',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}