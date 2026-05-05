-- =============================================================================
-- MilkGo Seed — Super Admin + Plans
-- Fully idempotent: safe to run multiple times, skips existing data.
-- PIN = 12345678 (bcrypt) — only set on first run, never overwritten.
-- =============================================================================

-- Enable pgcrypto (should already be enabled, just in case)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── 1. Super Admin user ──────────────────────────────────────────────────────
INSERT INTO public.users (id, phone, session_nonce)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '+918758223351',
  gen_random_uuid()
)
ON CONFLICT (id) DO NOTHING;

-- ── 2. Super Admin profile ───────────────────────────────────────────────────
INSERT INTO public.profiles (
  id, role, full_name, business_name,
  city, state, language,
  onboarding_completed, status,
  enabled_modules
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'super_admin',
  'Ravi Malaviya',
  'MilkGo',
  'Surat', 'Gujarat', 'gu',
  true, 'active',
  '["delivery","billing"]'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  role    = EXCLUDED.role,
  status  = EXCLUDED.status;

-- ── 3. Set PIN = 12345678 only if no PIN exists yet ──────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.user_pins
    WHERE user_id = '00000000-0000-0000-0000-000000000001'
  ) THEN
    PERFORM public.set_pin('00000000-0000-0000-0000-000000000001', '12345678');
  END IF;
END $$;

-- ── 4. Seed Plans (Free + Starter + Pro) ─────────────────────────────────────
INSERT INTO public.plans (
  name, slug, price_monthly, billing_cycle,
  max_customers, max_products, max_drivers,
  is_active, is_free, has_whatsapp, has_counter_mode, sort_order
)
VALUES
  ('Free',    'free',    0,   'monthly', 50,   5,  1, true, true,  true, true, 0),
  ('Starter', 'starter', 299, 'monthly', 200,  10, 2, true, false, true, true, 1),
  ('Pro',     'pro',     699, 'monthly', 1000, 25, 5, true, false, true, true, 2)
ON CONFLICT (slug) DO NOTHING;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅  MilkGo seed complete!';
  RAISE NOTICE '    Phone : +918758223351';
  RAISE NOTICE '    PIN   : 12345678 (only set if new)';
  RAISE NOTICE '';
END $$;
