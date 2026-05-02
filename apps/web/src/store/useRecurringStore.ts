import { create } from "zustand";
import { createClient } from "@/lib/supabase/client";
import type { RecurringPayment } from "@/types";

interface RecurringState {
  recurringPayments: RecurringPayment[];
  isLoading: boolean;
  error: string | null;
  fetchRecurring: () => Promise<void>;
  addRecurring: (data: Omit<RecurringPayment, "id" | "user_id">) => Promise<void>;
  updateRecurring: (id: string, data: Partial<RecurringPayment>) => Promise<void>;
  deleteRecurring: (id: string) => Promise<void>;
  executeRecurring: (rp: RecurringPayment) => Promise<void>;
  scheduleAutoDebit: (id: string) => Promise<void>;
  addDebtAutoPayment: (debtAccountId: string, fromAccountId: string, amount: number, dayOfMonth: number) => Promise<void>;
  checkAndSchedule: () => Promise<void>;
}

export const useRecurringStore = create<RecurringState>((set, get) => ({
  recurringPayments: [],
  isLoading: false,
  error: null,

  fetchRecurring: async () => {
    const supabase = createClient();
    set({ isLoading: true, error: null });
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { set({ isLoading: false }); return; }

    const { data, error } = await supabase
      .from("recurring_payments")
      .select("*, account:recurring_payments_account_id_fkey(*), category:categories(*)")
      .eq("user_id", user.id)
      .eq("status", "active")
      .order("next_payment_date");

    if (error) { set({ isLoading: false, error: error.message }); return; }
    set({ recurringPayments: (data as RecurringPayment[]) ?? [], isLoading: false });
    await get().checkAndSchedule();
  },

  addRecurring: async (data) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    await supabase.from("recurring_payments").insert({ ...data, user_id: user.id });
    await get().fetchRecurring();
  },

  updateRecurring: async (id, data) => {
    const supabase = createClient();
    await supabase.from("recurring_payments").update(data).eq("id", id);
    await get().fetchRecurring();
  },

  deleteRecurring: async (id) => {
    const supabase = createClient();
    await supabase.from("recurring_payments").delete().eq("id", id);
    set((s) => ({ recurringPayments: s.recurringPayments.filter(r => r.id !== id) }));
  },

  executeRecurring: async (rp) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data: accountData } = await supabase
      .from("accounts").select("balance").eq("id", rp.account_id).single();
    if (!accountData) return;

    await supabase.from("accounts")
      .update({ balance: accountData.balance - rp.amount })
      .eq("id", rp.account_id);

    if (rp.debt_account_id) {
      const { data: debtData } = await supabase
        .from("accounts").select("balance").eq("id", rp.debt_account_id).single();
      if (debtData) {
        await supabase.from("accounts")
          .update({ balance: debtData.balance - rp.amount })
          .eq("id", rp.debt_account_id);
      }
    }

    await supabase.from("transactions").insert({
      user_id: user.id,
      account_id: rp.account_id,
      category_id: rp.category_id ?? null,
      amount: -rp.amount,
      detail: rp.name,
      transaction_date: new Date().toISOString().split("T")[0],
      type: "expense",
      is_recurring: true,
    });

    const nextDate = new Date(rp.next_payment_date);
    nextDate.setMonth(nextDate.getMonth() + 1);
    const lastDay = new Date(nextDate.getFullYear(), nextDate.getMonth() + 1, 0).getDate();
    const adjustedDay = Math.min(rp.day_of_month, lastDay);
    nextDate.setDate(adjustedDay);

    await supabase.from("recurring_payments").update({
      last_executed_date: new Date().toISOString().split("T")[0],
      next_payment_date: nextDate.toISOString().split("T")[0],
      auto_debit_at: null,
    }).eq("id", rp.id);

    await get().fetchRecurring();
  },

  scheduleAutoDebit: async (id) => {
    const supabase = createClient();
    const autoDebitAt = new Date(Date.now() + 5 * 60 * 60 * 1000).toISOString();
    await supabase.from("recurring_payments").update({ auto_debit_at: autoDebitAt }).eq("id", id);
    await get().fetchRecurring();
  },

  addDebtAutoPayment: async (debtAccountId, fromAccountId, amount, dayOfMonth) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { data: debt } = await supabase.from("accounts").select("name").eq("id", debtAccountId).single();
    const now = new Date();
    const nextDate = new Date(now.getFullYear(), now.getMonth(), dayOfMonth);
    await supabase.from("recurring_payments").insert({
      user_id: user.id,
      name: `Pago ${debt?.name ?? "deuda"}`,
      amount,
      account_id: fromAccountId,
      day_of_month: dayOfMonth,
      next_payment_date: nextDate.toISOString().split("T")[0],
      is_auto: true,
      status: "active",
      debt_account_id: debtAccountId,
    });
    await get().fetchRecurring();
  },

  checkAndSchedule: async () => {
    const { recurringPayments } = get();
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    for (const rp of recurringPayments) {
      if (rp.status !== "active" || !rp.is_auto) continue;
      const due = new Date(rp.next_payment_date);
      if (due > today) continue;
      if (rp.auto_debit_at && new Date(rp.auto_debit_at) < now) {
        await get().executeRecurring(rp);
        continue;
      }
      if (!rp.auto_debit_at) {
        await get().scheduleAutoDebit(rp.id);
      }
    }
  },
}));