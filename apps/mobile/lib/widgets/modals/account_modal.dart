import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../models/models.dart';

const _accountTypes = ['efectivo', 'banco', 'ahorro', 'inversion', 'deuda', 'prestamo', 'otro'];
const _colors = ['#10B981', '#6C63FF', '#F59E0B', '#EF4444', '#3B82F6', '#EC4899', '#8B5CF6', '#14B8A6'];

class AccountModal extends ConsumerStatefulWidget {
  final Account? account;
  const AccountModal({super.key, this.account});

  @override
  ConsumerState<AccountModal> createState() => _AccountModalState();
}

class _AccountModalState extends ConsumerState<AccountModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  String _type = 'banco';
  String _color = '#10B981';
  bool _isLoading = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.account?.name ?? '');
    _balanceCtrl = TextEditingController(text: widget.account?.balance.toStringAsFixed(2) ?? '');
    _type  = widget.account?.type  ?? 'banco';
    _color = widget.account?.color ?? '#10B981';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {
        'name':    _nameCtrl.text.trim(),
        'type':    _type,
        'color':   _color,
        'balance': double.tryParse(_balanceCtrl.text) ?? 0.0,
        'is_active': true,
      };

      if (_isEditing) {
        await ref.read(financeProvider.notifier).updateAccount(widget.account!.id, data);
      } else {
        await ref.read(financeProvider.notifier).addAccount(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(_isEditing ? 'Editar cuenta' : 'Nueva cuenta',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: kMuted, size: 20),
                onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),

            // Nombre
            const Text('Nombre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: kText),
              decoration: const InputDecoration(hintText: 'Ej: Cuenta BHD'),
            ),
            const SizedBox(height: 16),

            // Balance
            const Text('Balance inicial', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kText),
              decoration: const InputDecoration(hintText: '0.00', prefixText: 'RD\$ '),
            ),
            const SizedBox(height: 16),

            // Tipo
            const Text('Tipo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _type,
              isExpanded: true,
              underline: Container(height: 1, color: kBorder),
              items: _accountTypes.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t[0].toUpperCase() + t.substring(1),
                  style: const TextStyle(color: kText, fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),

            // Color
            const Text('Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: _colors.map((c) {
              final selected = _color == c;
              final color = Color(int.parse(c.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: Colors.white, width: 2.5) : null,
                    boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
                  ),
                  child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                ),
              );
            }).toList()),
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
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoading
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text(_isEditing ? 'Guardar' : 'Crear',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}