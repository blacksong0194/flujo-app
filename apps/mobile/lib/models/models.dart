// ─── Account ─────────────────────────────────────────────────────────────────
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
    id:       j['id'],
    userId:   j['user_id'],
    name:     j['name'],
    type:     j['type'],
    balance:  (j['balance'] as num).toDouble(),
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

// ─── Category ─────────────────────────────────────────────────────────────────
class Category {
  final String id;
  final String userId;
  final String name;
  final int movementType; // 1=income, 2=expense
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
    id:           j['id'],
    userId:       j['user_id'],
    name:         j['name'],
    movementType: j['movement_type'],
    icon:         j['icon'] ?? '💰',
    color:        j['color'] ?? '#10b981',
  );
}

// ─── Transaction ──────────────────────────────────────────────────────────────
class Transaction {
  final String id;
  final String userId;
  final String accountId;
  final String categoryId;
  final double amount;
  final String detail;
  final DateTime transactionDate;
  final String type; // income | expense | transfer
  final bool isRecurring;
  final Account? account;
  final Category? category;

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
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id:              j['id'],
    userId:          j['user_id'],
    accountId:       j['account_id'],
    categoryId:      j['category_id'],
    amount:          (j['amount'] as num).toDouble(),
    detail:          j['detail'],
    transactionDate: DateTime.parse(j['transaction_date']),
    type:            j['type'],
    isRecurring:     j['is_recurring'] ?? false,
    account:  j['account']  != null ? Account.fromJson(j['account'])   : null,
    category: j['category'] != null ? Category.fromJson(j['category']) : null,
  );

  Map<String, dynamic> toInsertJson() => {
    'account_id':        accountId,
    'category_id':       categoryId,
    'amount':            amount,
    'detail':            detail,
    'transaction_date':  transactionDate.toIso8601String().split('T')[0],
    'type':              type,
    'is_recurring':      isRecurring,
  };
}

// ─── Budget ───────────────────────────────────────────────────────────────────
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
    id:             j['id'],
    userId:         j['user_id'],
    categoryId:     j['category_id'],
    amount:         (j['amount'] as num).toDouble(),
    period:         j['period'] ?? 'monthly',
    alertAtPercent: j['alert_at_percent'] ?? 80,
    category: j['category'] != null ? Category.fromJson(j['category']) : null,
  );
}

// ─── Goal ─────────────────────────────────────────────────────────────────────
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
    id:            j['id'],
    userId:        j['user_id'],
    name:          j['name'],
    description:   j['description'],
    targetAmount:  (j['target_amount'] as num).toDouble(),
    currentAmount: (j['current_amount'] as num).toDouble(),
    targetDate:    j['target_date'] != null ? DateTime.parse(j['target_date']) : null,
    color:         j['color'] ?? '#10b981',
  );

  Map<String, dynamic> toUpdateJson() => {
    'current_amount': currentAmount,
  };
}

// ─── Monthly Summary ─────────────────────────────────────────────────────────
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
    final egr = filtered.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    final aho = (ing - egr).clamp(0, double.infinity);
    return MonthlySummary(
      ingresos: ing,
      egresos: egr,
      ahorrado: aho,
      tasaAhorro: ing > 0 ? aho / ing : 0,
    );
  }
}
