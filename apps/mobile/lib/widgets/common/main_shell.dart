import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _Tab('/dashboard',    Icons.grid_view_rounded,    'Inicio'),
    _Tab('/transactions', Icons.swap_horiz_rounded,   'Movimientos'),
    _Tab('/accounts',     Icons.account_balance_wallet_rounded, 'Cuentas'),
    _Tab('/reports',      Icons.bar_chart_rounded,    'Reportes'),
    _Tab('/settings',     Icons.settings_outlined,    'Ajustes'),
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
    final index = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface2,
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: kBrand,
          unselectedItemColor: kMuted,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          onTap: (i) => context.go(_tabs[i].path),
          items: _tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon, size: 22),
            label: t.label,
          )).toList(),
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
