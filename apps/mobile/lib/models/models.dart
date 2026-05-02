class Account {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final String color;
  final bool isActive;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.isActive,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id:       j['id'] ?? '',
    userId:   j['user_id'] ?? '',
    name:     j['name'] ?? '',
    type:     j['type'] ?? 'cuenta',
    balance:  (j['balance'] as num? ?? 0).toDouble(),
    color:    j['color'] ?? '#10b981',
    isActive: j['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'user_id':   userId,
    'name':      name,
    'type':      type,
    'balance':   balance,
    'color':     color,
    'is_active': isActive,
  };
}

class Category {
  final String id;
  final String userId;
  final String name;
  final int movementType;
  final String icon;
  final String color;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.movementType,
    required this.icon,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id:           j['id'] ?? '',
    userId:       j['user_id'] ?? '',
    name:         j['name'] ?? '',
    movementType: j['movement_type'] ?? 2,
    icon:         j['icon'] ?? '',
    color:        j['color'] ?? '#10b981',
  );
}

class Transaction {
  final String id;
  final String userId;
  final String accountId;
  final String categoryId;
  final double amount;
  final String detail;
  final DateTime transactionDate;
  final String type;
  final bool isRecurring;
  final Account? account;
  final Category? category;
  final String? debtAccountId;

  const Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.detail,
    required this.transactionDate,
    required this.type,
    required this.isRecurring,
    this.account,
    this.category,
    this.debtAccountId,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id:              j['id'] ?? '',
    userId:          j['user_id'] ?? '',
    accountId:       j['account_id'] ?? '',
    categoryId:      j['category_id'] ?? '',
    amount:          (j['amount'] as num? ?? 0).toDouble(),
    detail:          j['detail'] ?? '',
    transactionDate: j['transaction_date'] != null ? DateTime.parse(j['transaction_date']) : DateTime.now(),
    type:            j['type'] ?? 'expense',
    isRecurring:     j['is_recurring'] ?? false,
    account:        j['account']  != null ? Account.fromJson(j['account'])   : null,
    category:       j['category'] != null ? Category.fromJson(j['category']) : null,
    debtAccountId:  j['debt_account_id'],
  );

  Map<String, dynamic> toInsertJson() => {
    'account_id':       accountId,
    'category_id':      categoryId,
    'amount':           amount,
    'detail':           detail,
    'transaction_date': transactionDate.toIso8601String().split('T')[0],
    'type':             type,
    'is_recurring':     isRecurring,
  };
}

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String period;
  final int alertAtPercent;
  final Category? category;

  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.alertAtPercent,
    this.category,
  });

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
    id:             j['id'] ?? '',
    userId:         j['user_id'] ?? '',
    categoryId:     j['category_id'] ?? '',
    amount:         (j['amount'] as num? ?? 0).toDouble(),
    period:         j['period'] ?? 'monthly',
    alertAtPercent: j['alert_at_percent'] ?? 80,
    category: j['category'] != null ? Category.fromJson(j['category']) : null,
  );
}

class Goal {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String color;

  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.color,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  bool get isCompleted => currentAmount >= targetAmount;

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
    id:            j['id'] ?? '',
    userId:        j['user_id'] ?? '',
    name:          j['name'] ?? '',
    description:   j['description'],
    targetAmount:  (j['target_amount'] as num? ?? 0).toDouble(),
    currentAmount: (j['current_amount'] as num? ?? 0).toDouble(),
    targetDate:    j['target_date'] != null ? DateTime.parse(j['target_date']) : null,
    color:         j['color'] ?? '#10b981',
  );

  Map<String, dynamic> toUpdateJson() => {
    'current_amount': currentAmount,
  };
}

class MonthlySummary {
  final double ingresos;
  final double egresos;
  final double ahorrado;
  final double tasaAhorro;

  const MonthlySummary({
    required this.ingresos,
    required this.egresos,
    required this.ahorrado,
    required this.tasaAhorro,
  });

  factory MonthlySummary.fromTransactions(List<Transaction> txs, int year, int month) {
    final filtered = txs.where((t) =>
      t.transactionDate.year == year && t.transactionDate.month == month
    );
    final ing = filtered.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final egr = filtered.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount.abs());
    final aho = (ing - egr).clamp(0.0, double.infinity);
    return MonthlySummary(
      ingresos:   ing,
      egresos:    egr,
      ahorrado:   aho,
      tasaAhorro: ing > 0 ? aho / ing : 0,
    );
  }
}

class PendingItem {
  final String id;
  final String userId;
  final String debtorName;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String status;

  const PendingItem({
    required this.id,
    required this.userId,
    required this.debtorName,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory PendingItem.fromJson(Map<String, dynamic> j) => PendingItem(
    id:          j['id'] ?? '',
    userId:      j['user_id'] ?? '',
    debtorName:  j['debtor_name'] ?? '',
    description: j['description'] ?? '',
    amount:      (j['amount'] as num? ?? 0).toDouble(),
    dueDate:     j['due_date'] != null ? DateTime.parse(j['due_date']) : DateTime.now(),
    status:      j['status'] ?? 'pending',
  );
}

class RecurringPayment {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String accountId;
  final String? categoryId;
  final int dayOfMonth;
  final DateTime nextPaymentDate;
  final DateTime? lastExecutedDate;
  final bool isAuto;
  final DateTime? autoDebitAt;
  final String status;
  final Account? account;
  final Category? category;
  final String? debtAccountId;

  const RecurringPayment({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.accountId,
    this.categoryId,
    required this.dayOfMonth,
    required this.nextPaymentDate,
    this.lastExecutedDate,
    required this.isAuto,
    this.autoDebitAt,
    required this.status,
    this.account,
    this.category,
    this.debtAccountId,
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> j) => RecurringPayment(
    id:               j['id'] ?? '',
    userId:           j['user_id'] ?? '',
    name:             j['name'] ?? '',
    amount:           (j['amount'] as num? ?? 0).toDouble(),
    accountId:        j['account_id'] ?? '',
    categoryId:       j['category_id'],
    dayOfMonth:       j['day_of_month'] ?? 1,
    nextPaymentDate:  DateTime.parse(j['next_payment_date']),
    lastExecutedDate: j['last_executed_date'] != null ? DateTime.parse(j['last_executed_date']) : null,
    isAuto:           j['is_auto'] ?? false,
    autoDebitAt:      j['auto_debit_at'] != null ? DateTime.parse(j['auto_debit_at']) : null,
    status:           j['status'] ?? 'active',
    account:       j['account']  != null ? Account.fromJson(j['account'])   : null,
    category:      j['category'] != null ? Category.fromJson(j['category']) : null,
    debtAccountId: j['debt_account_id'],
  );

  bool get isPending => status == 'active' &&
      nextPaymentDate.isBefore(DateTime.now().add(const Duration(days: 1)));

  bool get isInEditWindow => autoDebitAt != null &&
      DateTime.now().isBefore(autoDebitAt!);

  Duration get timeLeftInWindow => autoDebitAt != null
      ? autoDebitAt!.difference(DateTime.now())
      : Duration.zero;
}