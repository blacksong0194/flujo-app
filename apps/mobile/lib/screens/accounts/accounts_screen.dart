import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/modals/account_modal.dart';
import '../../models/models.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final liquid = state.accounts.where((a) => a.type != 'deuda' && a.type != 'prestamo').toList();
    final debts  = state.accounts.where((a) => a.type == 'deuda' || a.type == 'prestamo').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: kBrand),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AccountModal(),
            ),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: MetricCard(label: 'Líquido', value: fmtCompact(state.totalLiquid), accent: kBrand, icon: Icons.account_balance_wallet_rounded)),
          const SizedBox(width: 10),
          Expanded(child: MetricCard(label: 'Deudas', value: fmtCompact(state.totalDebt), accent: kRed, icon: Icons.warning_amber_rounded)),
        ]),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Cuentas activas'),
        if (liquid.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('Sin cuentas activas', style: TextStyle(color: kMuted))),
          )
        else
          ...liquid.map((a) => _AccountTile(account: a)),
        if (debts.isNotEmpty) ...[
          const SizedBox(height: 10),
          const SectionHeader(title: 'Deudas y Obligaciones'),
          ...debts.map((a) => _AccountTile(account: a, isDebt: true)),
        ],
      ]),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final bool isDebt;
  const _AccountTile({required this.account, this.isDebt = false});

  @override
  Widget build(BuildContext context) {
    final color = isDebt ? kRed : hexColor(account.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FCard(
        borderTop: color,
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(
              isDebt ? Icons.warning_amber_rounded : Icons.account_balance_rounded,
              color: color, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(account.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
            Text(account.type, style: const TextStyle(fontSize: 11, color: kMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtCompact(account.balance), style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: account.balance >= 0 ? kText : kRed)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => AccountModal(account: account),
              ),
              child: const Text('Editar', style: TextStyle(fontSize: 11, color: kBrand)),
            ),
          ]),
        ]),
      ),
    );
  }
}