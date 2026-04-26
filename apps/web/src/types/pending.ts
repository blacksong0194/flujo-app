// apps/web/src/types/pending.ts

export type PendingStatus = "pending" | "due_soon" | "overdue" | "collected";

export interface PendingPayment {
  id:              string;
  user_id:         string;
  debtor_name:     string;
  amount:          number;
  description:     string;
  due_date:        string;
  status:          "pending" | "collected";
  computed_status: PendingStatus;
  collected_date?: string;
  collected_in?:   string;
  transaction_id?: string;
  created_at:      string;
}

export interface PendingPaymentSummary {
  total:     number;
  overdue:   number;
  due_soon:  number;
  pending:   number;
  collected: number;
}
