"use client";
// apps/web/src/store/usePendingStore.ts
import { create } from "zustand";
import { createClient } from "@/lib/supabase/client";
import type { PendingPayment, PendingPaymentSummary } from "@/types/pending";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function calcComputedStatus(dueDate: string, status: string) {
  if (status === "collected") return "collected" as const;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const due      = new Date(dueDate);
  const diffDays = Math.ceil((due.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  if (diffDays < 0)  return "overdue"  as const;
  if (diffDays <= 3) return "due_soon" as const;
  return "pending" as const;
}

function calcSummary(payments: PendingPayment[]): PendingPaymentSummary {
  return {
    total:     payments.filter(p => p.status !== "collected").length,
    overdue:   payments.filter(p => p.computed_status === "overdue").length,
    due_soon:  payments.filter(p => p.computed_status === "due_soon").length,
    pending:   payments.filter(p => p.computed_status === "pending").length,
    collected: payments.filter(p => p.computed_status === "collected").length,
  };
}

// ─── State ───────────────────────────────────────────────────────────────────

interface PendingState {
  payments:  PendingPayment[];
  summary:   PendingPaymentSummary;
  isLoading: boolean;

  fetchPending:   () => Promise<void>;
  addPending:     (data: { debtor_name: string; amount: number; description?: string; due_date: string }) => Promise<void>;
  collectPending: (id: string, accountId: string) => Promise<{ success: boolean; error?: string }>;
  deletePending:  (id: string) => Promise<void>;
}

const emptySummary: PendingPaymentSummary = {
  total: 0, overdue: 0, due_soon: 0, pending: 0, collected: 0,
};

// ─── Store ────────────────────────────────────────────────────────────────────

export const usePendingStore = create<PendingState>((set, get) => ({
  payments:  [],
  summary:   emptySummary,
  isLoading: false,

  fetchPending: async () => {
    const supabase = createClient();
    set({ isLoading: true });

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { set({ isLoading: false }); return; }

    const { data, error } = await supabase
      .from("pending_payments")
      .select("*")
      .eq("user_id", user.id)
      .order("due_date", { ascending: true });

    if (error || !data) { set({ isLoading: false }); return; }

    const payments = data.map(p => ({
      ...p,
      computed_status: calcComputedStatus(p.due_date, p.status),
    })) as PendingPayment[];

    set({ payments, summary: calcSummary(payments), isLoading: false });
  },

  addPending: async ({ debtor_name, amount, description, due_date }) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data, error } = await supabase
      .from("pending_payments")
      .insert({
        user_id:     user.id,
        debtor_name: debtor_name.trim(),
        amount,
        description: description || "",
        due_date,
        status:      "pending",
      })
      .select()
      .single();

    if (error || !data) return;

    const newPayment: PendingPayment = {
      ...data,
      computed_status: calcComputedStatus(data.due_date, data.status),
    };

    set(s => {
      const payments = [...s.payments, newPayment].sort(
        (a, b) => new Date(a.due_date).getTime() - new Date(b.due_date).getTime()
      );
      return { payments, summary: calcSummary(payments) };
    });
  },

  collectPending: async (id, accountId) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: "No autorizado" };

    const payment = get().payments.find(p => p.id === id);
    if (!payment) return { success: false, error: "Pago no encontrado" };

    const { data: account, error: accErr } = await supabase
      .from("accounts")
      .select("id, balance")
      .eq("id", accountId)
      .eq("user_id", user.id)
      .single();

    if (accErr || !account) return { success: false, error: "Cuenta no encontrada" };

    const today = new Date().toISOString().split("T")[0];

    const { data: transaction, error: txErr } = await supabase
      .from("transactions")
      .insert({
        user_id:          user.id,
        account_id:       accountId,
        amount:           payment.amount,
        type:             "income",
        detail:           `Cobro de ${payment.debtor_name}${payment.description ? ` — ${payment.description}` : ""}`,
        transaction_date: today,
      })
      .select()
      .single();

    if (txErr || !transaction) return { success: false, error: txErr?.message };

    await supabase
      .from("accounts")
      .update({ balance: account.balance + payment.amount })
      .eq("id", accountId);

    const { error: updateErr } = await supabase
      .from("pending_payments")
      .update({
        status:         "collected",
        collected_date: today,
        collected_in:   accountId,
        transaction_id: transaction.id,
      })
      .eq("id", id)
      .eq("user_id", user.id);

    if (updateErr) return { success: false, error: updateErr.message };

    set(s => {
      const payments = s.payments.map(p =>
        p.id === id
          ? { ...p, status: "collected" as const, computed_status: "collected" as const,
              collected_date: today, collected_in: accountId, transaction_id: transaction.id }
          : p
      );
      return { payments, summary: calcSummary(payments) };
    });

    return { success: true };
  },

  deletePending: async (id) => {
    const supabase = createClient();
    await supabase.from("pending_payments").delete().eq("id", id);
    set(s => {
      const payments = s.payments.filter(p => p.id !== id);
      return { payments, summary: calcSummary(payments) };
    });
  },
}));
