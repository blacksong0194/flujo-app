import { create } from "zustand";
import { createClient } from "@/lib/supabase/client";
import type {
  User, Account, Category, Transaction, Budget, Goal,
  MonthlySummary, Alert,
} from "@/types";
import {
  calcMonthlySummary, calcTrend, calcTotalLiquid,
  calcTotalDebt, calcNetWorth, generateAlerts,
} from "@/lib/finance";

interface FinanceState {
  // Auth
  user: User | null;
  // Data
  accounts: Account[];
  categories: Category[];
  transactions: Transaction[];
  budgets: Budget[];
  goals: Goal[];
  // UI state
  selectedYear: number;
  selectedMonth: number;
  isLoading: boolean;
  // Computed
  summary: MonthlySummary | null;
  alerts: Alert[];
  totalLiquid: number;
  totalDebt: number;
  netWorth: number;
  // Actions
  setUser: (user: User | null) => void;
  setPeriod: (year: number, month: number) => void;
  fetchAll: () => Promise<void>;
  addTransaction: (t: Omit<Transaction, "id" | "user_id" | "created_at">) => Promise<void>;
  updateTransaction: (id: string, data: Partial<Transaction>) => Promise<void>;
  deleteTransaction: (id: string) => Promise<void>;
  addAccount: (a: Omit<Account, "id" | "user_id" | "created_at">) => Promise<void>;
  updateAccount: (id: string, data: Partial<Account>) => Promise<void>;
  addBudget: (b: Omit<Budget, "id" | "user_id">) => Promise<void>;
  addGoal: (g: Omit<Goal, "id" | "user_id">) => Promise<void>;
  updateGoal: (id: string, data: Partial<Goal>) => Promise<void>;
  recompute: () => void;
}

const now = new Date();

export const useFinanceStore = create<FinanceState>((set, get) => ({
  user: null,
  accounts: [],
  categories: [],
  transactions: [],
  budgets: [],
  goals: [],
  selectedYear: now.getFullYear(),
  selectedMonth: now.getMonth() + 1,
  isLoading: false,
  summary: null,
  alerts: [],
  totalLiquid: 0,
  totalDebt: 0,
  netWorth: 0,

  setUser: (user) => set({ user }),

  setPeriod: (year, month) => {
    set({ selectedYear: year, selectedMonth: month });
    get().recompute();
  },

  recompute: () => {
    const { accounts, transactions, selectedYear, selectedMonth } = get();
    const summary = calcMonthlySummary(transactions, selectedYear, selectedMonth);
    const alerts = generateAlerts(accounts, transactions, selectedYear, selectedMonth);
    set({
      summary,
      alerts,
      totalLiquid: calcTotalLiquid(accounts),
      totalDebt: calcTotalDebt(accounts),
      netWorth: calcNetWorth(accounts),
    });
  },

  fetchAll: async () => {
    const supabase = createClient();
    set({ isLoading: true });
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { set({ isLoading: false }); return; }

    const [
      { data: accounts },
      { data: categories },
      { data: transactions },
      { data: budgets },
      { data: goals },
    ] = await Promise.all([
      supabase.from("accounts").select("*").eq("user_id", user.id).eq("is_active", true).order("name"),
      supabase.from("categories").select("*").eq("user_id", user.id).order("name"),
      supabase.from("transactions").select("*, account:accounts(*), category:categories(*)").eq("user_id", user.id).order("created_at", { ascending: false }).limit(500),
      supabase.from("budgets").select("*, category:categories(*)").eq("user_id", user.id),
      supabase.from("goals").select("*").eq("user_id", user.id).order("created_at"),
    ]);

    set({
      accounts: accounts ?? [],
      categories: categories ?? [],
      transactions: (transactions as unknown as Transaction[]) ?? [],
      budgets: (budgets as unknown as Budget[]) ?? [],
      goals: goals ?? [],
      isLoading: false,
    });
    get().recompute();
  },

  addTransaction: async (txData) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const store = get();

    // Manejar transferencias especialmente
    if (txData.type === "transfer") {
      // Crear transacción de salida
      const { data: outData } = await supabase
        .from("transactions")
        .insert({ ...txData, user_id: user.id })
        .select("*, account:accounts(*), category:categories(*)")
        .single();

      if (outData) {
        // Actualizar balance de cuenta de salida
        const fromAccount = store.accounts.find(a => a.id === txData.account_id);
        if (fromAccount) {
          const newFromBalance = fromAccount.balance + txData.amount; // amount es negativo
          await supabase.from("accounts").update({ balance: newFromBalance }).eq("id", fromAccount.id);
        }

        // Crear transacción de entrada en cuenta destino
        const toAccountId = (txData as any).to_account_id;
        const { data: inData } = await supabase
          .from("transactions")
          .insert({
            account_id: toAccountId,
            user_id: user.id,
            amount: Math.abs(txData.amount),
            type: "transfer",
            detail: txData.detail,
            transaction_date: txData.transaction_date,
            category_id: null,
            is_recurring: false,
          })
          .select("*, account:accounts(*), category:categories(*)")
          .single();

        if (inData) {
          // Actualizar balance de cuenta de entrada
          const toAccount = store.accounts.find(a => a.id === toAccountId);
          if (toAccount) {
            const newToBalance = toAccount.balance + Math.abs(txData.amount);
            await supabase.from("accounts").update({ balance: newToBalance }).eq("id", toAccount.id);
          }

          // Actualizar estado con ambas transacciones
          set((s) => ({
            transactions: [inData as unknown as Transaction, outData as unknown as Transaction, ...s.transactions],
            accounts: s.accounts.map(a => {
              if (a.id === txData.account_id) {
                return { ...a, balance: store.accounts.find(x => x.id === a.id)?.balance ?? 0 + txData.amount };
              }
              if (a.id === toAccountId) {
                return { ...a, balance: store.accounts.find(x => x.id === a.id)?.balance ?? 0 + Math.abs(txData.amount) };
              }
              return a;
            })
          }));
        }
      }
    } else {
      // Transacciones normales (ingreso/egreso)
      const { data } = await supabase
        .from("transactions")
        .insert({ ...txData, user_id: user.id })
        .select("*, account:accounts(*), category:categories(*)")
        .single();

      if (data) {
        set((s) => ({ transactions: [data as unknown as Transaction, ...s.transactions] }));

        // Update account balance
        const account = store.accounts.find(a => a.id === txData.account_id);
        if (account) {
          const newBalance = txData.type === "income"
            ? account.balance + txData.amount
            : account.balance - txData.amount;
          await supabase.from("accounts").update({ balance: newBalance }).eq("id", account.id);
          set((s) => ({
            accounts: s.accounts.map(a => a.id === account.id ? { ...a, balance: newBalance } : a)
          }));
        }
      }
    }

    get().recompute();
  },
addTransaction: async (txData) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const store = get();

    // Manejar transferencias especialmente
    if (txData.type === "transfer") {
      // Crear transacción de salida
      const { data: outData } = await supabase
        .from("transactions")
        .insert({ ...txData, user_id: user.id })
        .select("*, account:accounts(*), category:categories(*)")
        .single();

      if (outData) {
        // Actualizar balance de cuenta de salida
        const fromAccount = store.accounts.find(a => a.id === txData.account_id);
        if (fromAccount) {
          const newFromBalance = fromAccount.balance + txData.amount;
          await supabase.from("accounts").update({ balance: newFromBalance }).eq("id", fromAccount.id);
        }

        // Crear transacción de entrada en cuenta destino
        const toAccountId = (txData as any).to_account_id;
        const { data: inData } = await supabase
          .from("transactions")
          .insert({
            account_id: toAccountId,
            user_id: user.id,
            amount: Math.abs(txData.amount),
            type: "transfer",
            detail: txData.detail,
            transaction_date: txData.transaction_date,
            category_id: null,
            is_recurring: false,
          })
          .select("*, account:accounts(*), category:categories(*)")
          .single();

        if (inData) {
          const toAccount = store.accounts.find(a => a.id === toAccountId);
          if (toAccount) {
            const newToBalance = toAccount.balance + Math.abs(txData.amount);
            await supabase.from("accounts").update({ balance: newToBalance }).eq("id", toAccount.id);
          }

          set((s) => ({
            transactions: [inData as unknown as Transaction, outData as unknown as Transaction, ...s.transactions],
            accounts: s.accounts.map(a => {
              if (a.id === txData.account_id) return { ...a, balance: (store.accounts.find(x => x.id === a.id)?.balance ?? 0) + txData.amount };
              if (a.id === toAccountId) return { ...a, balance: (store.accounts.find(x => x.id === a.id)?.balance ?? 0) + Math.abs(txData.amount) };
              return a;
            })
          }));
        }
      }
    } else {
      const { data } = await supabase
        .from("transactions")
        .insert({ ...txData, user_id: user.id })
        .select("*, account:accounts(*), category:categories(*)")
        .single();

      if (data) {
        set((s) => ({ transactions: [data as unknown as Transaction, ...s.transactions] }));
        const account = store.accounts.find(a => a.id === txData.account_id);
        if (account) {
          const newBalance = txData.type === "income"
            ? account.balance + txData.amount
            : account.balance - txData.amount;
          await supabase.from("accounts").update({ balance: newBalance }).eq("id", account.id);
          set((s) => ({
            accounts: s.accounts.map(a => a.id === account.id ? { ...a, balance: newBalance } : a)
          }));
        }
      }
    }

    get().recompute();
  },

  updateTransaction: async (id, txData) => {
    const supabase = createClient();
    const { data } = await supabase
      .from("transactions")
      .update(txData)
      .eq("id", id)
      .select("*, account:accounts(*), category:categories(*)")
      .single();
    if (data) {
      set((s) => ({
        transactions: s.transactions.map(t => t.id === id ? data as unknown as Transaction : t)
      }));
      get().recompute();
    }
  },

  deleteTransaction: async (id) => {
    const supabase = createClient();
    await supabase.from("transactions").delete().eq("id", id);
    set((s) => ({ transactions: s.transactions.filter(t => t.id !== id) }));
    get().recompute();
  },

  addAccount: async (acctData) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { data } = await supabase
      .from("accounts")
      .insert({ ...acctData, user_id: user.id })
      .select()
      .single();
    if (data) {
      set((s) => ({ accounts: [...s.accounts, data] }));
      get().recompute();
    }
  },

  updateAccount: async (id, acctData) => {
    const supabase = createClient();
    const { data } = await supabase.from("accounts").update(acctData).eq("id", id).select().single();
    if (data) {
      set((s) => ({ accounts: s.accounts.map(a => a.id === id ? { ...a, ...data } : a) }));
      get().recompute();
    }
  },

  addBudget: async (bData) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { data } = await supabase
      .from("budgets")
      .insert({ ...bData, user_id: user.id })
      .select("*, category:categories(*)")
      .single();
    if (data) set((s) => ({ budgets: [...s.budgets, data as unknown as Budget] }));
  },

  addGoal: async (gData) => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { data } = await supabase
      .from("goals")
      .insert({ ...gData, user_id: user.id })
      .select()
      .single();
    if (data) set((s) => ({ goals: [...s.goals, data] }));
  },

  updateGoal: async (id, gData) => {
    const supabase = createClient();
    const { data } = await supabase.from("goals").update(gData).eq("id", id).select().single();
    if (data) set((s) => ({ goals: s.goals.map(g => g.id === id ? { ...g, ...data } : g) }));
  },
}));
