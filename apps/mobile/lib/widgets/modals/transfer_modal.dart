import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../models/models.dart';

class TransferModal extends ConsumerStatefulWidget {
  const TransferModal({super.key});
  @override
  ConsumerState<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends ConsumerState<TransferModal> {
  late TextEditingController _amountCtrl;
  late TextEditingController _detailCtrl;
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _detailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona ambas cuentas')),
      );
      return;
    }
    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las cuentas deben ser diferentes')),
      );
      return;
    }
    if (_amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountCtrl.text);
      final state = ref.read(financeProvider);
      final fromAccount = state.accounts.firstWhere((a) => a.id == _fromAccountId);
      final toAccount = state.accounts.firstWhere((a) => a.id == _toAccountId);

      // Transacción de salida
      await ref.read(financeProvider.notifier).addTransaction({
        'account_id': _fromAccountId,
        'category_id': null,
        'amount': -amount,
        'detail': 'Transferencia a ${toAccount.name}',
        'transaction_date': _selectedDate.toIso8601String(),
        'type': 'transfer',
        'is_recurring': false,
      });

      // Transacción de entrada
      await ref.read(financeProvider.notifier).addTransaction({
        'account_id': _toAccountId,
        'category_id': null,
        'amount': amount,
        'detail': 'Transferencia desde ${fromAccount.name}',
        'transaction_date': _selectedDate.toIso8601String(),
        'type': 'transfer',
        'is_recurring': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transferencia completada')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final activeAccounts = state.accounts.where((a) => a.isActive).toList();
    final destinationAccounts = activeAccounts.where((a) => a.id != _fromAccountId).toList();

    final fromAccount = activeAccounts.cast<Account?>().firstWhere((a) => a?.id == _fromAccountId, orElse: () => null);
    final toAccount = activeAccounts.cast<Account?>().firstWhere((a) => a?.id == _toAccountId, orElse: () => null);
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    return Dialog(
      backgroundColor: kBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Transferencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
              IconButton(icon: const Icon(Icons.close_rounded, color: kMuted, size: 20), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),

            Text('Fecha', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: kText, fontSize: 13)),
                  const Icon(Icons.calendar_today_rounded, color: kMuted, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            Text('Monto (RD\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(hintText: '0.00', prefixText: 'RD\$ ', prefixStyle: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),

            Text('Cuenta DE (salida)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _fromAccountId,
              isExpanded: true,
              underline: Container(height: 1, color: kBorder),
              items: activeAccounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text('${a.name} (RD\$ ${a.balance.toStringAsFixed(2)})', style: const TextStyle(color: kText, fontSize: 13)),
              )).toList(),
              onChanged: (val) => setState(() { _fromAccountId = val; _toAccountId = null; }),
            ),
            const SizedBox(height: 16),

            Text('Cuenta A (entrada)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _toAccountId,
              isExpanded: true,
              underline: Container(height: 1, color: kBorder),
              items: destinationAccounts.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text('${a.name} (RD\$ ${a.balance.toStringAsFixed(2)})', style: const TextStyle(color: kText, fontSize: 13)),
              )).toList(),
              onChanged: (val) => setState(() => _toAccountId = val),
            ),
            const SizedBox(height: 16),

            if (fromAccount != null && toAccount != null && amount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kBrand.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: kBrand.withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Resumen:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(fromAccount.name, style: const TextStyle(fontSize: 12, color: kText)),
                    Text('RD\$ ${(fromAccount.balance - amount).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(toAccount.name, style: const TextStyle(fontSize: 12, color: kText)),
                    Text('RD\$ ${(toAccount.balance + amount).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: kSurface, foregroundColor: kMuted, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: kBrand, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Transferir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
