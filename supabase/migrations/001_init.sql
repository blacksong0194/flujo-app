-- ============================================================
-- FLUJO Finance OS — Database Schema v1.0
-- Run in Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Users profile (extends auth.users) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   TEXT,
  avatar_url  TEXT,
  currency    CHAR(3)  DEFAULT 'DOP',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── Accounts (Almacenes) ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.accounts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('banco','cooperativa','efectivo','inversion','deuda','prestamo')),
  balance     NUMERIC(15,2) DEFAULT 0,
  color       TEXT DEFAULT '#10b981',
  icon        TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  notes       TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_accounts_user ON public.accounts(user_id);

-- ─── Categories ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  movement_type   SMALLINT NOT NULL CHECK (movement_type IN (1, 2)), -- 1=income, 2=expense
  icon            TEXT DEFAULT '💰',
  color           TEXT DEFAULT '#10b981',
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id);

-- ─── Transactions ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id        UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
  category_id       UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  amount            NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  detail            TEXT NOT NULL,
  transaction_date  DATE NOT NULL,
  type              TEXT NOT NULL CHECK (type IN ('income','expense','transfer')),
  is_recurring      BOOLEAN DEFAULT FALSE,
  recurrence_rule   TEXT,  -- RRULE format e.g. FREQ=MONTHLY;BYDAY=1
  notes             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user        ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date        ON public.transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_account     ON public.transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category    ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date   ON public.transactions(user_id, transaction_date DESC);

-- ─── Budgets ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.budgets (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id       UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  amount            NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  period            TEXT DEFAULT 'monthly' CHECK (period IN ('monthly','weekly','yearly')),
  alert_at_percent  SMALLINT DEFAULT 80 CHECK (alert_at_percent BETWEEN 1 AND 100),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category_id, period)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user ON public.budgets(user_id);

-- ─── Goals ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  description     TEXT,
  target_amount   NUMERIC(15,2) NOT NULL CHECK (target_amount > 0),
  current_amount  NUMERIC(15,2) DEFAULT 0 CHECK (current_amount >= 0),
  target_date     DATE,
  color           TEXT DEFAULT '#10b981',
  is_completed    BOOLEAN GENERATED ALWAYS AS (current_amount >= target_amount) STORED,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goals_user ON public.goals(user_id);

-- ─── Notifications ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL, -- 'budget_alert','goal_milestone','debt_warning'
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  is_read     BOOLEAN DEFAULT FALSE,
  related_id  UUID,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);

-- ─── Updated_at trigger ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql
AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['accounts','transactions','goals','profiles']
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS set_updated_at ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()', t
    );
  END LOOP;
END $$;

-- ─── Row Level Security ───────────────────────────────────────────────────────
ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policies: each user sees only their own data
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'accounts','categories','transactions',
    'budgets','goals','notifications'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Users own data" ON public.%I', tbl);
    EXECUTE format(
      'CREATE POLICY "Users own data" ON public.%I
       FOR ALL TO authenticated
       USING (auth.uid() = user_id)
       WITH CHECK (auth.uid() = user_id)', tbl
    );
  END LOOP;
END $$;

-- Special policy for profiles (uses id instead of user_id)
DROP POLICY IF EXISTS "Users own data" ON public.profiles;
CREATE POLICY "Users own profile" ON public.profiles
  FOR ALL TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ─── Helpful DB Views ────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_monthly_summary AS
SELECT
  t.user_id,
  DATE_TRUNC('month', t.transaction_date) AS period,
  SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE 0 END) AS ingresos,
  SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) AS egresos,
  SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE -t.amount END) AS neto
FROM public.transactions t
GROUP BY t.user_id, DATE_TRUNC('month', t.transaction_date);

CREATE OR REPLACE VIEW public.v_account_balances AS
SELECT
  a.id,
  a.user_id,
  a.name,
  a.type,
  a.color,
  a.balance,
  COUNT(t.id) AS transaction_count
FROM public.accounts a
LEFT JOIN public.transactions t ON t.account_id = a.id
WHERE a.is_active = TRUE
GROUP BY a.id;

-- ============================================================
-- SEED: Default categories (run per user after registration)
-- Replace 'YOUR_USER_ID' with the actual UUID
-- ============================================================
-- INSERT INTO public.categories (user_id, name, movement_type, icon, color) VALUES
--   ('YOUR_USER_ID', 'Ing. de ajuste',  1, '⚖️', '#64748b'),
--   ('YOUR_USER_ID', 'Ing. x salario',  1, '💼', '#10b981'),
--   ('YOUR_USER_ID', 'Ing. x asesoría', 1, '🎯', '#3b82f6'),
--   ('YOUR_USER_ID', 'Ing. x arriendo', 1, '🏠', '#8b5cf6'),
--   ('YOUR_USER_ID', 'Ing. x inversión',1, '📈', '#f59e0b'),
--   ('YOUR_USER_ID', 'Egr. de ajuste',  2, '⚖️', '#64748b'),
--   ('YOUR_USER_ID', 'Ser. Públicos',   2, '💡', '#f59e0b'),
--   ('YOUR_USER_ID', 'Alimentación',    2, '🍽️', '#10b981'),
--   ('YOUR_USER_ID', 'Compras',         2, '🛍️', '#ec4899'),
--   ('YOUR_USER_ID', 'Pólizas',         2, '🛡️', '#3b82f6'),
--   ('YOUR_USER_ID', 'Renta',           2, '🏠', '#8b5cf6'),
--   ('YOUR_USER_ID', 'Salud & Pensión', 2, '❤️', '#ef4444'),
--   ('YOUR_USER_ID', 'Impuestos',       2, '🏛️', '#6366f1'),
--   ('YOUR_USER_ID', 'Membresías',      2, '🔖', '#06b6d4'),
--   ('YOUR_USER_ID', 'Reparaciones',    2, '🔧', '#f97316'),
--   ('YOUR_USER_ID', 'Esparcimientos',  2, '🎉', '#84cc16'),
--   ('YOUR_USER_ID', 'Educación',       2, '📚', '#3b82f6'),
--   ('YOUR_USER_ID', 'Transporte',      2, '🚗', '#f59e0b'),
--   ('YOUR_USER_ID', 'Despensas',       2, '🛒', '#10b981'),
--   ('YOUR_USER_ID', 'Vestuarios',      2, '👕', '#ec4899'),
--   ('YOUR_USER_ID', 'Medicinas',       2, '💊', '#ef4444');
