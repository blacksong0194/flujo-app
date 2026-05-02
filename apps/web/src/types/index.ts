// ─── Core domain types ────────────────────────────────────────────────────────

export type MovementType = "income" | "expense" | "transfer";
export type AccountType =
  | "banco"
  | "cooperativa"
  | "efectivo"
  | "inversion"
  | "deuda"
  | "prestamo";
export type PeriodType = "monthly" | "weekly" | "yearly";

export interface User {
  id: string;
  email: string;
  full_name: string;
  avatar_url?: string;
  currency: string;
  created_at: string;
}

export interface Account {
  id: string;
  user_id: string;
  name: string;
  type: AccountType;
  balance: number;
  color: string;
  icon?: string;
  is_active: boolean;
  created_at: string;
}

export interface Category {
  id: string;
  user_id: string;
  name: string;
  movement_type: 1 | 2; // 1=income, 2=expense
  icon: string;
  color: string;
}

export interface Transaction {
  id: string;
  user_id: string;
  account_id: string;
  category_id: string;
  amount: number;
  detail: string;
  transaction_date: string;
  type: MovementType;
  is_recurring: boolean;
  recurrence_rule?: string;
  created_at: string;
  // Joined
  account?: Account;
  category?: Category;
}

export interface Budget {
  id: string;
  user_id: string;
  category_id: string;
  amount: number;
  period: PeriodType;
  alert_at_percent: number;
  // Computed
  spent?: number;
  remaining?: number;
  percent_used?: number;
  category?: Category;
}

export interface Goal {
  id: string;
  user_id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date?: string;
  color: string;
  description?: string;
  // Computed
  progress_percent?: number;
  monthly_needed?: number;
  eta_months?: number;
}

// ─── Dashboard & Report types ─────────────────────────────────────────────────

export interface MonthlySummary {
  year: number;
  month: number;
  ingresos: number;
  egresos: number;
  ahorrado: number;
  tasa_ahorro: number;
}

export interface AccountBalance {
  account_id: string;
  account_name: string;
  account_type: AccountType;
  balance: number;
  color: string;
}

export interface CategoryTotal {
  category_id: string;
  category_name: string;
  category_color: string;
  total: number;
  count: number;
  movement_type: 1 | 2;
}

export interface TrendDataPoint {
  month: string;
  ingresos: number;
  egresos: number;
  neto: number;
}

export interface Alert {
  id: string;
  type: "danger" | "warning" | "info";
  title: string;
  message: string;
  account_id?: string;
  category_id?: string;
}

export interface RecurringPayment {
  id: string;
  user_id: string;
  name: string;
  amount: number;
  account_id: string;
  category_id?: string;
  day_of_month: number;
  next_payment_date: string;
  last_executed_date?: string;
  is_auto: boolean;
  auto_debit_at?: string;
  status: 'active' | 'paused' | 'cancelled';
  debt_account_id?: string;
  // Joined
  account?: Account;
  category?: Category;
}