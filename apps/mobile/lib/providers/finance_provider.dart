import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

class FinanceState {
  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<PendingItem> pendingItems;
  final List<RecurringPayment> recurringPayments;
  final int selectedYear;
  final int selectedMonth;
  final bool isLoading;
  final String? error;

  const FinanceState({
    this.accounts          = const [],
    this.categories        = const [],
    this.transactions      = const [],
    this.budgets           = const [],
    this.goals             = const [],
    this.pendingItems      = const [],
    this.recurringPayments = const [],
    required this.selectedYear,
    required this.selectedMonth,
    this.isLoading = false,
    this.error,
  });

  FinanceState copyWith({
    List<Account>?          accounts,
    List<Category>?         categories,
    List<Transaction>?      transactions,
    List<Budget>?           budgets,
    List<Goal>?             goals,
    List<PendingItem>?      pendingItems,
    List<RecurringPayment>? recurringPayments,
    int?                    selectedYear,
    int?                    selectedMonth,
    bool?                   isLoading,
    Object?                 error = _sentinel,
  }) => FinanceState(
    accounts:          accounts          ?? this.accounts,
    categories:        categories        ?? this.categories,
    transactions:      transactions      ?? this.transactions,
    budgets:           budgets           ?? this.budgets,
    goals:             goals             ?? this.goals,
    pendingItems:      pendingItems      ?? this.pendingItems,
    recurringPayments: recurringPayments ?? this.recurringPayments,
    selectedYear:      selectedYear      ?? this.selectedYear,
    selectedMonth:     selectedMonth     ?? this.selectedMonth,
    isLoading:         isLoading         ?? this.isLoading,
    error: error == _sentinel ? this.error : error as String?,
  );

  double get totalLiquid => accounts
      .where((a) => a.type != 'deuda' && a.type != 'prestamo')
      .fold(0.0, (s, a) => s + a.balance);

  double get totalDebt => accounts
      .where((a) => a.type == 'deuda' || a.type == 'prestamo')
      .fold(0.0, (s, a) => s + a.balance.abs());

  double get netWorth => accounts.fold(
    0.0,
    (s, a) => a.type == 'deuda' || a.type == 'prestamo'
        ? s - a.balance.abs()
        : s + a.balance,
  );

  MonthlySummary get summary =>
      MonthlySummary.fromTransactions(transactions, selectedYear, selectedMonth);
}

const _sentinel = Object();

class FinanceNotifier extends Notifier<FinanceState> {
  late SupabaseClient _client;

  @override
  FinanceState build() {
    _client = ref.watch(supabaseProvider);

    ref.listen(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn) fetchAll();
        if (authState.event == AuthChangeEvent.signedOut) {
          state = FinanceState(
            selectedYear: DateTime.now().year,
            selectedMonth: DateTime.now().month,
          );
        }
      });
    });

    final user = _client.auth.currentUser;
    if (user != null) Future.microtask(() => fetchAll());

    return FinanceState(
      selectedYear: DateTime.now().year,
      selectedMonth: DateTime.now().month,
    );
  }

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _client.auth.currentUser;
      if (user == null) { state = state.copyWith(isLoading: false); return; }

      final results = await Future.wait([
        _client.from('accounts').select().eq('user_id', user.id).eq('is_active', true).order('name'),
        _client.from('categories').select().eq('user_id', user.id).order('name'),
        _client.from('transactions')
            .select('*, account:accounts(*), category:categories(*)')
            .eq('user_id', user.id)
            .order('transaction_date', ascending: false)
            .limit(500),
        _client.from('budgets').select('*, category:categories(*)').eq('user_id', user.id),
        _client.from('goals').select().eq('user_id', user.id).order('created_at'),
        _client.from('pending_payments').select().eq('user_id', user.id).order('due_date'),
        _client.from('recurring_payments')
            .select('*, account:recurring_payments_account_id_fkey(*), category:categories(*)')
            .eq('user_id', user.id)
            .eq('status', 'active')
            .order('next_payment_date'),
      ]);

      state = state.copyWith(
        accounts:          (results[0] as List).map((j) => Account.fromJson(j)).toList(),
        categories:        (results[1] as List).map((j) => Category.fromJson(j)).toList(),
        transactions:      (results[2] as List).map((j) => Transaction.fromJson(j)).toList(),
        budgets:           (results[3] as List).map((j) => Budget.fromJson(j)).toList(),
        goals:             (results[4] as List).map((j) => Goal.fromJson(j)).toList(),
        pendingItems:      (results[5] as List).map((j) => PendingItem.fromJson(j)).toList(),
        recurringPayments: (results[6] as List).map((j) => RecurringPayment.fromJson(j)).toList(),
        isLoading: false,
        error: null,
      );
      await _checkAndScheduleRecurring();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _checkAndScheduleRecurring() async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final rp in state.recurringPayments) {
      if (rp.status != 'active' || !rp.isAuto) continue;
      final dueDate = DateTime(
        rp.nextPaymentDate.year,
        rp.nextPaymentDate.month,
        rp.nextPaymentDate.day,
      );
      if (dueDate.isAfter(today)) continue;
      if (rp.autoDebitAt != null && now.isAfter(rp.autoDebitAt!)) {
        await executeRecurringPayment(rp);
        continue;
      }
      if (rp.autoDebitAt == null) {
        await scheduleAutoDebit(rp.id);
      }
    }
  }

  void setPeriod(int year, int month) =>
      state = state.copyWith(selectedYear: year, selectedMonth: month);

  Future<void> addTransaction(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser!;
    await _client.from('transactions').insert({...data, 'user_id': user.id});
    final accountId = data['account_id'];
    final amount = (data['amount'] as num).toDouble();
    if (accountId != null) {
      final account = state.accounts.firstWhere((a) => a.id == accountId);
      await _client.from('accounts')
          .update({'balance': account.balance + amount})
          .eq('id', accountId);
    }
    await fetchAll();
  }

  Future<void> payDebt(String debtAccountId, String fromAccountId, double amount) async {
    final debt = state.accounts.firstWhere((a) => a.id == debtAccountId);
    final from = state.accounts.firstWhere((a) => a.id == fromAccountId);
    await _client.from('accounts').update({'balance': debt.balance - amount}).eq('id', debtAccountId);
    await _client.from('accounts').update({'balance': from.balance - amount}).eq('id', fromAccountId);
    final user = _client.auth.currentUser!;
    await _client.from('transactions').insert({
      'user_id':          user.id,
      'account_id':       fromAccountId,
      'category_id':      null,
      'amount':           -amount,
      'detail':           'Pago a ${debt.name}',
      'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      'type':             'expense',
      'is_recurring':     false,
    });
    await fetchAll();
  }

  Future<void> addDebt(String debtAccountId, String toAccountId, double amount) async {
    final debt = state.accounts.firstWhere((a) => a.id == debtAccountId);
    final to   = state.accounts.firstWhere((a) => a.id == toAccountId);
    await _client.from('accounts').update({'balance': debt.balance + amount}).eq('id', debtAccountId);
    await _client.from('accounts').update({'balance': to.balance + amount}).eq('id', toAccountId);
    final user = _client.auth.currentUser!;
    await _client.from('transactions').insert({
      'user_id':          user.id,
      'account_id':       toAccountId,
      'category_id':      null,
      'amount':           amount,
      'detail':           'Nueva deuda: ${debt.name}',
      'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      'type':             'income',
      'is_recurring':     false,
    });
    await fetchAll();
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
    await fetchAll();
  }

  Future<void> addAccount(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser!;
    final res = await _client.from('accounts').insert({...data, 'user_id': user.id}).select().single();
    state = state.copyWith(accounts: [...state.accounts, Account.fromJson(res)]);
  }

  Future<void> updateAccount(String id, Map<String, dynamic> data) async {
    await _client.from('accounts').update(data).eq('id', id);
    await fetchAll();
  }

  Future<void> updateGoal(String id, double newAmount) async {
    await _client.from('goals').update({'current_amount': newAmount}).eq('id', id);
    state = state.copyWith(
      goals: state.goals.map((g) => g.id == id
          ? Goal(
              id:            g.id,
              userId:        g.userId,
              name:          g.name,
              description:   g.description,
              targetAmount:  g.targetAmount,
              currentAmount: newAmount,
              targetDate:    g.targetDate,
              color:         g.color,
            )
          : g).toList(),
    );
  }

  Future<void> addGoal(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser!;
    final res = await _client.from('goals').insert({...data, 'user_id': user.id}).select().single();
    state = state.copyWith(goals: [...state.goals, Goal.fromJson(res)]);
  }

  Future<void> addBudget(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser!;
    final res = await _client.from('budgets')
        .insert({...data, 'user_id': user.id})
        .select('*, category:categories(*)')
        .single();
    state = state.copyWith(budgets: [...state.budgets, Budget.fromJson(res)]);
  }

  Future<void> addPendingItem(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser!;
    final res = await _client.from('pending_payments')
        .insert({...data, 'user_id': user.id})
        .select()
        .single();
    state = state.copyWith(pendingItems: [...state.pendingItems, PendingItem.fromJson(res)]);
  }

  // FIX: 'description' -> 'detail', 'date' -> 'transaction_date', agrega paidAmount y is_recurring
  Future<void> markPendingCollected(String id, String accountId, double paidAmount) async {
    final user = _client.auth.currentUser!;
    final item = state.pendingItems.firstWhere((p) => p.id == id);
    final isFullyPaid = paidAmount >= item.amount;

    await _client.from('transactions').insert({
      'user_id':          user.id,
      'account_id':       accountId,
      'category_id':      null,
      'amount':           paidAmount,
      'type':             'income',
      'detail':           'Cobro: ${item.debtorName} - ${item.description}',
      'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      'is_recurring':     false,
    });

    final acc = state.accounts.firstWhere((a) => a.id == accountId);
    await _client.from('accounts')
        .update({'balance': acc.balance + paidAmount})
        .eq('id', accountId);

    if (isFullyPaid) {
      await _client.from('pending_payments')
          .update({'status': 'collected'}).eq('id', id);
    } else {
      await _client.from('pending_payments')
          .update({'amount': item.amount - paidAmount}).eq('id', id);
    }

    await fetchAll();
  }

  Future<void> deletePendingItem(String id) async {
    await _client.from('pending_payments').delete().eq('id', id);
    state = state.copyWith(
      pendingItems: state.pendingItems.where((p) => p.id != id).toList(),
    );
  }

  Future<void> addRecurringPayment(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser!;
    await _client.from('recurring_payments').insert({...data, 'user_id': user.id});
    await fetchAll();
  }

  Future<void> updateRecurringPayment(String id, Map<String, dynamic> data) async {
    await _client.from('recurring_payments').update(data).eq('id', id);
    await fetchAll();
  }

  Future<void> deleteRecurringPayment(String id) async {
    await _client.from('recurring_payments').delete().eq('id', id);
    await fetchAll();
  }

  Future<void> addDebtAutoPayment(String debtAccountId, String fromAccountId, double amount, int dayOfMonth) async {
    final debt = state.accounts.firstWhere((a) => a.id == debtAccountId);
    final user = _client.auth.currentUser!;
    final now  = DateTime.now();
    final nextDate = DateTime(now.year, now.month, dayOfMonth);
    await _client.from('recurring_payments').insert({
      'user_id':           user.id,
      'name':              'Pago ${debt.name}',
      'amount':            amount,
      'account_id':        fromAccountId,
      'day_of_month':      dayOfMonth,
      'next_payment_date': nextDate.toIso8601String().split('T')[0],
      'is_auto':           true,
      'status':            'active',
      'debt_account_id':   debtAccountId,
    });
    await fetchAll();
  }

  Future<void> executeRecurringPayment(RecurringPayment rp) async {
    final account = state.accounts.firstWhere((a) => a.id == rp.accountId);
    final user = _client.auth.currentUser!;

    await _client.from('accounts')
        .update({'balance': account.balance - rp.amount})
        .eq('id', rp.accountId);

    if (rp.debtAccountId != null) {
      final debt = state.accounts.firstWhere(
        (a) => a.id == rp.debtAccountId, orElse: () => account);
      await _client.from('accounts')
          .update({'balance': debt.balance - rp.amount})
          .eq('id', rp.debtAccountId!);
    }

    await _client.from('transactions').insert({
      'user_id':          user.id,
      'account_id':       rp.accountId,
      'category_id':      rp.categoryId,
      'amount':           -rp.amount,
      'detail':           rp.name,
      'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      'type':             'expense',
      'is_recurring':     true,
    });

    final nextMonth      = rp.nextPaymentDate.month + 1;
    final nextYear       = nextMonth > 12 ? rp.nextPaymentDate.year + 1 : rp.nextPaymentDate.year;
    final adjustedMonth  = nextMonth > 12 ? 1 : nextMonth;
    final lastDayOfMonth = DateTime(nextYear, adjustedMonth + 1, 0).day;
    final adjustedDay    = rp.dayOfMonth > lastDayOfMonth ? lastDayOfMonth : rp.dayOfMonth;
    final next           = DateTime(nextYear, adjustedMonth, adjustedDay);

    await _client.from('recurring_payments').update({
      'last_executed_date': DateTime.now().toIso8601String().split('T')[0],
      'next_payment_date':  next.toIso8601String().split('T')[0],
      'auto_debit_at':      null,
    }).eq('id', rp.id);

    await fetchAll();
  }

  Future<void> scheduleAutoDebit(String id) async {
    final autoDebitAt = DateTime.now().add(const Duration(hours: 5));
    await _client.from('recurring_payments').update({
      'auto_debit_at': autoDebitAt.toIso8601String(),
    }).eq('id', id);
    await fetchAll();
  }
}

final financeProvider = NotifierProvider<FinanceNotifier, FinanceState>(
  FinanceNotifier.new,
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});