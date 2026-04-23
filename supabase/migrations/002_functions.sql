-- ============================================================
-- FLUJO — Migration 002: Stored procedures for reports
-- ============================================================

-- ─── Monthly summary for a specific user+period ───────────────────────────────
CREATE OR REPLACE FUNCTION public.get_monthly_summary(
  p_user_id UUID,
  p_year    INT,
  p_month   INT
)
RETURNS TABLE (
  ingresos   NUMERIC,
  egresos    NUMERIC,
  ahorrado   NUMERIC,
  tasa_ahorro NUMERIC
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_ing  NUMERIC;
  v_egr  NUMERIC;
  v_aho  NUMERIC;
BEGIN
  SELECT
    COALESCE(SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
  INTO v_ing, v_egr
  FROM public.transactions
  WHERE user_id         = p_user_id
    AND EXTRACT(YEAR  FROM transaction_date) = p_year
    AND EXTRACT(MONTH FROM transaction_date) = p_month;

  v_aho := GREATEST(v_ing - v_egr, 0);

  RETURN QUERY SELECT
    v_ing,
    v_egr,
    v_aho,
    CASE WHEN v_ing > 0 THEN v_aho / v_ing ELSE 0 END;
END;
$$;

-- ─── Category totals for a period ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_category_totals(
  p_user_id     UUID,
  p_year        INT,
  p_month       INT,
  p_movement_type SMALLINT  -- 1=income, 2=expense
)
RETURNS TABLE (
  category_id   UUID,
  category_name TEXT,
  category_color TEXT,
  total         NUMERIC,
  tx_count      BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.color,
    COALESCE(SUM(t.amount), 0) AS total,
    COUNT(t.id) AS tx_count
  FROM public.categories c
  LEFT JOIN public.transactions t ON t.category_id = c.id
    AND t.user_id = p_user_id
    AND EXTRACT(YEAR  FROM t.transaction_date) = p_year
    AND EXTRACT(MONTH FROM t.transaction_date) = p_month
    AND t.type = CASE WHEN p_movement_type = 1 THEN 'income' ELSE 'expense' END
  WHERE c.user_id = p_user_id
    AND c.movement_type = p_movement_type
  GROUP BY c.id, c.name, c.color
  HAVING COALESCE(SUM(t.amount), 0) > 0
  ORDER BY total DESC;
END;
$$;

-- ─── Account net balances view (recalculated) ──────────────────────────────
CREATE OR REPLACE FUNCTION public.recalc_account_balance(p_account_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE v_balance NUMERIC;
BEGIN
  SELECT COALESCE(SUM(
    CASE WHEN type = 'income' THEN amount
         WHEN type = 'expense' THEN -amount
         ELSE 0 END
  ), 0)
  INTO v_balance
  FROM public.transactions
  WHERE account_id = p_account_id;
  RETURN v_balance;
END;
$$;

-- ─── Budget utilization for current month ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_budget_utilization(p_user_id UUID)
RETURNS TABLE (
  budget_id    UUID,
  category_id  UUID,
  category_name TEXT,
  budget_amount NUMERIC,
  spent         NUMERIC,
  percent_used  NUMERIC,
  status        TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.id,
    b.category_id,
    c.name,
    b.amount,
    COALESCE(SUM(t.amount), 0) AS spent,
    CASE WHEN b.amount > 0
         THEN ROUND(COALESCE(SUM(t.amount), 0) / b.amount * 100, 1)
         ELSE 0 END AS percent_used,
    CASE
      WHEN COALESCE(SUM(t.amount), 0) >= b.amount THEN 'over'
      WHEN COALESCE(SUM(t.amount), 0) >= b.amount * (b.alert_at_percent / 100.0) THEN 'warning'
      ELSE 'ok'
    END AS status
  FROM public.budgets b
  JOIN public.categories c ON c.id = b.category_id
  LEFT JOIN public.transactions t
    ON t.category_id = b.category_id
   AND t.user_id = p_user_id
   AND t.type = 'expense'
   AND DATE_TRUNC('month', t.transaction_date) = DATE_TRUNC('month', NOW())
  WHERE b.user_id = p_user_id
    AND b.period = 'monthly'
  GROUP BY b.id, b.category_id, c.name, b.amount, b.alert_at_percent;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_monthly_summary      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_category_totals      TO authenticated;
GRANT EXECUTE ON FUNCTION public.recalc_account_balance   TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_budget_utilization   TO authenticated;
