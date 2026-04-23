import { format, startOfMonth, endOfMonth, subMonths } from "date-fns";
import { es } from "date-fns/locale";
import type {
  Transaction,
  Account,
  MonthlySummary,
  TrendDataPoint,
  CategoryTotal,
  Alert,
} from "@/types";

// ─── Formatters ───────────────────────────────────────────────────────────────

export function formatCurrency(
  amount: number,
  currency = "DOP",
  compact = false
): string {
  if (compact) {
    const abs = Math.abs(amount);
    const sign = amount < 0 ? "-" : "";
    if (abs >= 1_000_000) return `${sign}RD$${(abs / 1_000_000).toFixed(1)}M`;
    if (abs >= 1_000) return `${sign}RD$${(abs / 1_000).toFixed(0)}K`;
    return `${sign}RD$${abs.toFixed(0)}`;
  }
  return new Intl.NumberFormat("es-DO", {
    style: "currency",
    currency,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function formatPercent(value: number): string {
  return `${(value * 100).toFixed(1)}%`;
}

export function formatDate(date: string): string {
  return format(new Date(date + "T00:00:00"), "d MMM yyyy", { locale: es });
}

export function formatMonthYear(year: number, month: number): string {
  const d = new Date(year, month - 1, 1);
  return format(d, "MMMM yyyy", { locale: es });
}

// ─── Balance calculations ─────────────────────────────────────────────────────

export function calcAccountBalance(
  accountId: string,
  transactions: Transaction[]
): number {
  return transactions
    .filter((t) => t.account_id === accountId)
    .reduce((sum, t) => {
      if (t.type === "income") return sum + t.amount;
      if (t.type === "expense") return sum - t.amount;
      return sum; // transfer handled separately
    }, 0);
}

export function calcTotalLiquid(accounts: Account[]): number {
  return accounts
    .filter((a) => a.type !== "deuda" && a.type !== "prestamo")
    .reduce((sum, a) => sum + a.balance, 0);
}

export function calcTotalDebt(accounts: Account[]): number {
  return accounts
    .filter((a) => a.type === "deuda" || a.type === "prestamo")
    .reduce((sum, a) => sum + Math.abs(a.balance), 0);
}

export function calcNetWorth(accounts: Account[]): number {
  return accounts.reduce((sum, a) => {
    if (a.type === "deuda" || a.type === "prestamo") return sum - Math.abs(a.balance);
    return sum + a.balance;
  }, 0);
}

// ─── Period calculations ──────────────────────────────────────────────────────

export function filterByPeriod(
  transactions: Transaction[],
  year: number,
  month: number
): Transaction[] {
  const start = startOfMonth(new Date(year, month - 1, 1));
  const end = endOfMonth(new Date(year, month - 1, 1));
  return transactions.filter((t) => {
    const d = new Date(t.transaction_date + "T00:00:00");
    return d >= start && d <= end;
  });
}

export function calcMonthlySummary(
  transactions: Transaction[],
  year: number,
  month: number
): MonthlySummary {
  const filtered = filterByPeriod(transactions, year, month);
  const ingresos = filtered
    .filter((t) => t.type === "income")
    .reduce((s, t) => s + t.amount, 0);
  const egresos = filtered
    .filter((t) => t.type === "expense")
    .reduce((s, t) => s + t.amount, 0);
  const ahorrado = Math.max(ingresos - egresos, 0);
  const tasa_ahorro = ingresos > 0 ? ahorrado / ingresos : 0;
  return { year, month, ingresos, egresos, ahorrado, tasa_ahorro };
}

export function calcTrend(
  transactions: Transaction[],
  months = 6
): TrendDataPoint[] {
  const now = new Date();
  const result: TrendDataPoint[] = [];
  for (let i = months - 1; i >= 0; i--) {
    const d = subMonths(now, i);
    const y = d.getFullYear();
    const m = d.getMonth() + 1;
    const summary = calcMonthlySummary(transactions, y, m);
    result.push({
      month: format(d, "MMM", { locale: es }),
      ingresos: summary.ingresos,
      egresos: summary.egresos,
      neto: summary.ingresos - summary.egresos,
    });
  }
  return result;
}

export function calcCategoryTotals(
  transactions: Transaction[],
  type: "income" | "expense"
): CategoryTotal[] {
  const map = new Map<string, CategoryTotal>();
  transactions
    .filter((t) => t.type === type && t.category)
    .forEach((t) => {
      const key = t.category_id;
      const existing = map.get(key);
      if (existing) {
        existing.total += t.amount;
        existing.count++;
      } else {
        map.set(key, {
          category_id: t.category_id,
          category_name: t.category?.name ?? "Sin categoría",
          category_color: t.category?.color ?? "#64748b",
          total: t.amount,
          count: 1,
          movement_type: type === "income" ? 1 : 2,
        });
      }
    });
  return Array.from(map.values()).sort((a, b) => b.total - a.total);
}

// ─── Budget calculations ──────────────────────────────────────────────────────

export function calcBudgetProgress(
  budgetAmount: number,
  spent: number
): { remaining: number; percent: number; status: "ok" | "warning" | "over" } {
  const remaining = budgetAmount - spent;
  const percent = budgetAmount > 0 ? (spent / budgetAmount) * 100 : 0;
  const status = percent >= 100 ? "over" : percent >= 80 ? "warning" : "ok";
  return { remaining, percent, status };
}

// ─── Goal calculations ────────────────────────────────────────────────────────

export function calcGoalProgress(
  targetAmount: number,
  currentAmount: number,
  targetDate?: string,
  monthlySaving?: number
): {
  progress_percent: number;
  monthly_needed: number;
  eta_months: number | null;
} {
  const progress_percent = targetAmount > 0
    ? Math.min((currentAmount / targetAmount) * 100, 100)
    : 0;
  const remaining = Math.max(targetAmount - currentAmount, 0);
  let eta_months: number | null = null;
  let monthly_needed = 0;

  if (targetDate) {
    const now = new Date();
    const end = new Date(targetDate);
    const monthsLeft = Math.max(
      (end.getFullYear() - now.getFullYear()) * 12 +
        (end.getMonth() - now.getMonth()),
      1
    );
    monthly_needed = remaining / monthsLeft;
  } else if (monthlySaving && monthlySaving > 0) {
    eta_months = Math.ceil(remaining / monthlySaving);
    monthly_needed = monthlySaving;
  }

  return { progress_percent, monthly_needed, eta_months };
}

// ─── Alerts engine ────────────────────────────────────────────────────────────

export function generateAlerts(
  accounts: Account[],
  transactions: Transaction[],
  year: number,
  month: number
): Alert[] {
  const alerts: Alert[] = [];
  const summary = calcMonthlySummary(transactions, year, month);

  // Negative balance accounts
  accounts
    .filter((a) => a.balance < 0 && a.type !== "deuda" && a.type !== "prestamo")
    .forEach((a) => {
      alerts.push({
        id: `neg-${a.id}`,
        type: "danger",
        title: "Saldo negativo",
        message: `${a.name} tiene saldo negativo (${formatCurrency(a.balance)})`,
        account_id: a.id,
      });
    });

  // High debt ratio
  const liquid = calcTotalLiquid(accounts);
  const debt = calcTotalDebt(accounts);
  if (debt > 0 && liquid > 0) {
    const ratio = debt / (liquid + debt);
    if (ratio > 0.85) {
      alerts.push({
        id: "debt-ratio",
        type: "danger",
        title: "Ratio de endeudamiento crítico",
        message: `Tu deuda representa el ${formatPercent(ratio)} del total de activos`,
      });
    } else if (ratio > 0.6) {
      alerts.push({
        id: "debt-ratio-warn",
        type: "warning",
        title: "Endeudamiento elevado",
        message: `Tu deuda representa el ${formatPercent(ratio)} del total de activos`,
      });
    }
  }

  // Low savings rate
  if (summary.ingresos > 0 && summary.tasa_ahorro < 0.1) {
    alerts.push({
      id: "savings-low",
      type: "warning",
      title: "Tasa de ahorro baja",
      message: `Solo estás ahorrando el ${formatPercent(summary.tasa_ahorro)} de tus ingresos este mes`,
    });
  }

  return alerts;
}
