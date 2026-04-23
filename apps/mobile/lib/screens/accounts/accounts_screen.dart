// accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_provider.dart';
import '../../services/theme.dart';
import '../../widgets/common/widgets.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final liquid = state.accounts.where((a) => a.type != 'deuda' && a.type != 'prestamo').toList();
    final debts  = state.accounts.where((a) => a.type == 'deuda' || a.type == 'prestamo').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Summary
        Row(children: [
          Expanded(child: MetricCard(label: 'Líquido', value: fmtCompact(state.totalLiquid), accent: kBrand, icon: Icons.account_balance_wallet_rounded)),
          const SizedBox(width: 10),
          Expanded(child: MetricCard(label: 'Deudas', value: fmtCompact(state.totalDebt), accent: kRed, icon: Icons.warning_amber_rounded)),
        ]),
        const SizedBox(height: 20),

        // Liquid accounts
        const SectionHeader(title: 'Cuentas activas'),
        ...liquid.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FCard(
            borderTop: hexColor(a.color),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: hexColor(a.color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.account_balance_rounded, color: hexColor(a.color), size: 18)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                Text(a.type, style: const TextStyle(fontSize: 11, color: kMuted)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmtCurrency(a.balance), style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: a.balance >= 0 ? kText : kRed)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: a.balance >= 0 ? kBrand.withOpacity(0.1) : kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(a.balance >= 0 ? 'Activo' : 'Sobregirado',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: a.balance >= 0 ? kBrand : kRed))),
              ]),
            ]),
          ),
        )),

        if (debts.isNotEmpty) ...[
          const SizedBox(height: 10),
          const SectionHeader(title: 'Deudas & Obligaciones'),
          ...debts.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FCard(
              borderTop: kRed,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: kRed, size: 18),
                  const SizedBox(width: 8),
                  Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                  const Spacer(),
                  Text(fmtCurrency(a.balance), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kRed)),
                ]),
                const SizedBox(height: 10),
                FProgressBar(percent: 78),
                const SizedBox(height: 4),
                const Text('78% del límite utilizado', style: TextStyle(fontSize: 11, color: kMuted)),
              ]),
            ),
          )),
        ],
      ]),
    );
  }
}
