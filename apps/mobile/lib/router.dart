import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/accounts/accounts_screen.dart';
import 'screens/budgets/budgets_screen.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/pending/pending_screen.dart';
import 'widgets/common/main_shell.dart';
import 'screens/recurring/recurring_screen.dart';

// Notifier que escucha cambios de sesión de Supabase
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthNotifier();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth  = session != null;
      final inAuth  = state.matchedLocation.startsWith('/auth');
      if (!isAuth && !inAuth) return '/auth/login';
      if (isAuth && inAuth)  return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
          GoRoute(path: '/accounts',     builder: (_, __) => const AccountsScreen()),
          GoRoute(path: '/pending',      builder: (_, __) => const PendingScreen()),
          GoRoute(path: '/budgets',      builder: (_, __) => const BudgetsScreen()),
          GoRoute(path: '/goals',        builder: (_, __) => const GoalsScreen()),
          GoRoute(path: '/reports',      builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/settings',     builder: (_, __) => const SettingsScreen()),
	GoRoute(path: '/recurring', builder: (_, __) => const RecurringScreen()),
        ],
      ),
    ],
  );
});