import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../models/models.dart';

class DebtModal extends ConsumerStatefulWidget {
  final Account debtAccount;
  const DebtModal({super.key, required this.debtAccount});

  @override
  ConsumerState<DebtModal> createState() => _DebtModalState();
}

class _DebtModalState extends ConsumerState<DebtModal> {
  String _mode = 'pay';
  final _amountCtrl = TextEditingController();
  String? _liquidAccountId;
  bool _autoPayment = false;
  int _autoDay = 1;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _liquidAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: kRed));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto valido'), backgroundColor: kRed));
      return;
    }

    setState(() => _loading = true);
    try {
      if (_mode == 'pay') {
        await ref.read(financeProvider.notifier).payDebt(
          widget.debtAccount.id, _liquidAccountId!, amount);
        if (_autoPayment) {
          await ref.read(financeProvider.notifier).addDebtAutoPayment(
            widget.debtAccount.id, _liquidAccountId!, amount, _autoDay);
        }
      } else {
        await ref.read(financeProvider.notifier).addDebt(
          widget.debtAccount.id, _liquidAccountId!, amount);
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
    final state = ref.watch(financeProvider);
    final liquidAccounts = state.accounts
        .where((a) => a.type != 'deuda' && a.type != 'prestamo' && a.isActive)
        .toList();

    final isPay  = _mode == 'pay';
    final accent = isPay ? kBrand : kRed;

    return Dialog(
      backgroundColor: kBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gestionar deuda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
              Text(widget.debtAccount.name,
                style: const TextStyle(fontSize: 12, color: kMuted)),
            ])),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: kMuted, size: 20),
              onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),

          // Balance actual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kRed.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Balance actual', style: TextStyle(fontSize: 12, color: kMuted)),
              Text(fmtCompact(widget.debtAccount.balance),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kRed)),
            ]),
          ),
          const SizedBox(height: 16),

          // Selector modo
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _mode = 'pay'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isPay ? kBrand.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(color: isPay ? kBrand : kBorder),
                ),
                child: Center(child: Text('↑ Pagar deuda',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isPay ? kBrand : kMuted))),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () => setState(() { _mode = 'add'; _autoPayment = false; }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: !isPay ? kRed.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(color: !isPay ? kRed : kBorder),
                ),
                child: Center(child: Text('↓ Nueva deuda',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: !isPay ? kRed : kMuted))),
              ),
            )),
          ]),
          const SizedBox(height: 16),

          // Monto
          const Text('Monto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '0.00', prefixText: 'RD\$ '),
          ),
          const SizedBox(height: 16),

          // Cuenta
          Text(isPay ? 'Pagar desde cuenta' : 'Acreditar a cuenta',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _liquidAccountId,
            dropdownColor: kSurface,
            style: const TextStyle(color: kText, fontSize: 13),
            decoration: InputDecoration(
              labelText: isPay ? 'Selecciona cuenta origen' : 'Selecciona cuenta destino',
            ),
            items: liquidAccounts.map((a) => DropdownMenuItem(
              value: a.id, child: Text(a.name),
            )).toList(),
            onChanged: (v) => setState(() => _liquidAccountId = v),
          ),

          // Preview balances
          if (_liquidAccountId != null && _amountCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Builder(builder: (_) {
              final amount    = double.tryParse(_amountCtrl.text) ?? 0;
              final liquid    = state.accounts.firstWhere((a) => a.id == _liquidAccountId);
              final newDebt   = isPay ? widget.debtAccount.balance - amount : widget.debtAccount.balance + amount;
              final newLiquid = isPay ? liquid.balance - amount : liquid.balance + amount;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurface2.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(child: Text(widget.debtAccount.name,
                      style: const TextStyle(fontSize: 12, color: kMuted),
                      overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(fmtCompact(newDebt),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: isPay ? kBrand : kRed)),
                  ]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(child: Text(liquid.name,
                      style: const TextStyle(fontSize: 12, color: kMuted),
                      overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(fmtCompact(newLiquid),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: newLiquid >= 0 ? kText : kRed)),
                  ]),
                ]),
              );
            }),
          ],

          // Toggle pago automatico (solo en modo pay)
          if (isPay) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface2.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _autoPayment ? kBrand.withOpacity(0.4) : kBorder),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pago automatico mensual',
                      style: TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('Se debita cada mes automaticamente',
                      style: TextStyle(color: kMuted, fontSize: 11)),
                  ])),
                  Switch(
                    value: _autoPayment,
                    onChanged: (v) => setState(() => _autoPayment = v),
                    activeColor: kBrand),
                ]),
                if (_autoPayment) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Dia del mes:', style: TextStyle(color: kMuted, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _autoDay.toDouble(),
                        min: 1, max: 31,
                        divisions: 30,
                        activeColor: kBrand,
                        label: 'Dia $_autoDay',
                        onChanged: (v) => setState(() => _autoDay = v.round()),
                      ),
                    ),
                    Text('$_autoDay',
                      style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ],
              ]),
            ),
          ],

          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSurface, foregroundColor: kMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _loading
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text(isPay ? 'Pagar' : 'Agregar deuda',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}