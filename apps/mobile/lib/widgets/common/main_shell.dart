import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _Tab('/dashboard',    Icons.grid_view_rounded,              'Inicio'),
    _Tab('/transactions', Icons.swap_horiz_rounded,             'Movimientos'),
    _Tab('/accounts',     Icons.account_balance_wallet_rounded, 'Cuentas'),
    _Tab('/pending',      Icons.access_time_rounded,            'Por cobrar'),
    _Tab('/recurring',    Icons.repeat_rounded,                 'Recurrentes'),
    _Tab('/budgets',      Icons.pie_chart_outline_rounded,      'Presupuesto'),
    _Tab('/goals',        Icons.track_changes_rounded,          'Metas'),
    _Tab('/reports',      Icons.bar_chart_rounded,              'Reportes'),
    _Tab('/settings',     Icons.settings_outlined,              'Ajustes'),
  ];

  int _indexFor(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface2,
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                final tab = _tabs[i];
                final isSelected = i == selectedIndex;
                return GestureDetector(
                  onTap: () => context.go(tab.path),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tab.icon, size: 22, color: isSelected ? kBrand : kMuted),
                        const SizedBox(height: 3),
                        Text(tab.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? kBrand : kMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: isSelected ? 20 : 0,
                          decoration: BoxDecoration(
                            color: kBrand,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData icon;
  final String label;
  const _Tab(this.path, this.icon, this.label);
}
