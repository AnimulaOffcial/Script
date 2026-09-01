-- ==============================================================================
-- ANIMULA OFFICIAL — SUPABASE SCHEMA & STORED PROCEDURES
-- Project: eiykqbkfljqxwfqdffpo
-- Dashboard SQL Editor: https://supabase.com/dashboard/project/eiykqbkfljqxwfqdffpo/sql
-- ==============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA pg_catalog;

-- ==============================================================================
-- Main Keys Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.animula_keys (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  token               TEXT NOT NULL UNIQUE,                                             -- 50 char generate token /web/generetekey/XXXX
  get_token           TEXT UNIQUE,                                                      -- 50 char getkey token /web/getkey/XXXX (HMAC)
  animula_key         TEXT UNIQUE,                                                      -- Animula-fs-XXXXXXXXXXXXXXXXXXXX (20) or Animula-ps-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX (50)
  roblox_username     TEXT NOT NULL,
  roblox_id           BIGINT NOT NULL,
  roblox_display_name TEXT,
  roblox_avatar       TEXT,
  plan                TEXT NOT NULL DEFAULT '24h' CHECK (plan IN ('24h', '7d', '30d', 'lifetime')),
  is_unlimited        BOOLEAN NOT NULL DEFAULT FALSE,                                   -- TRUE for lifetime
  duration_hours      INT,                                                              -- 24 for 24h, 168 for 7d, 720 for 30d, NULL for lifetime
  state               TEXT NOT NULL DEFAULT 'CREATED' CHECK (state IN ('CREATED', 'LOOT_STARTED', 'LOOT_COMPLETED', 'CLAIMED', 'EXPIRED')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  loot_started_at     TIMESTAMPTZ,
  loot_completed_at   TIMESTAMPTZ,
  expires_at          TIMESTAMPTZ,                                                      -- generate link expiry (15m)
  get_expires_at      TIMESTAMPTZ,                                                      -- getkey link expiry (24h)
  key_expires_at      TIMESTAMPTZ,                                                      -- actual key expiry (NULL = unlimited)
  claimed             BOOLEAN NOT NULL DEFAULT FALSE,
  claimed_at          TIMESTAMPTZ,
  last_checked_at     TIMESTAMPTZ DEFAULT NOW(),
  last_used_at        TIMESTAMPTZ,
  use_count           INT NOT NULL DEFAULT 0,
  ip_hash             TEXT,
  user_agent          TEXT,

  -- Constraints
  CONSTRAINT token_format           CHECK (token ~ '^[A-Za-z0-9]{50}$'),
  CONSTRAINT get_token_format       CHECK (get_token IS NULL OR get_token ~ '^[A-Za-z0-9]{50}$'),
  CONSTRAINT animula_key_format     CHECK (animula_key IS NULL OR animula_key ~ '^Animula-(fs-[A-Za-z0-9]{20}|ps-[A-Za-z0-9]{50})$'),
  CONSTRAINT roblox_username_format CHECK (roblox_username ~ '^[A-Za-z0-9_]{3,20}$'),
  CONSTRAINT duration_check         CHECK ((is_unlimited = TRUE AND duration_hours IS NULL AND key_expires_at IS NULL) OR (is_unlimited = FALSE AND duration_hours IS NOT NULL))
);

-- ==============================================================================
-- Indexes for Fast Lookup
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_keys_token              ON public.animula_keys(token);
CREATE INDEX IF NOT EXISTS idx_keys_get_token          ON public.animula_keys(get_token);
CREATE INDEX IF NOT EXISTS idx_keys_animula            ON public.animula_keys(animula_key);
CREATE INDEX IF NOT EXISTS idx_keys_roblox_id          ON public.animula_keys(roblox_id);
CREATE INDEX IF NOT EXISTS idx_keys_roblox_username    ON public.animula_keys(roblox_username);
CREATE INDEX IF NOT EXISTS idx_keys_state              ON public.animula_keys(state);
CREATE INDEX IF NOT EXISTS idx_keys_plan               ON public.animula_keys(plan);
CREATE INDEX IF NOT EXISTS idx_keys_created_at         ON public.animula_keys(created_at);
CREATE INDEX IF NOT EXISTS idx_keys_expires_at         ON public.animula_keys(expires_at);
CREATE INDEX IF NOT EXISTS idx_keys_key_expires_at     ON public.animula_keys(key_expires_at);
CREATE INDEX IF NOT EXISTS idx_keys_claimed            ON public.animula_keys(claimed);

-- Partial index for active keys per user (max 1 check)
CREATE INDEX IF NOT EXISTS idx_keys_active_per_user    ON public.animula_keys(roblox_id, key_expires_at) 
  WHERE state IN ('LOOT_COMPLETED', 'CLAIMED') AND (is_unlimited OR key_expires_at > NOW());

-- ==============================================================================
-- Trigger Function: Set Duration & Expiry by Plan
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.set_key_expiry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.plan = 'lifetime' THEN
    NEW.is_unlimited    := TRUE;
    NEW.duration_hours  := NULL;
    NEW.key_expires_at  := NULL;
    NEW.expires_at      := COALESCE(NEW.expires_at, NOW() + INTERVAL '15 minutes');
    NEW.get_expires_at  := COALESCE(NEW.get_expires_at, NOW() + INTERVAL '24 hours');
  ELSIF NEW.plan = '24h' THEN
    NEW.is_unlimited    := FALSE;
    NEW.duration_hours  := 24;
    NEW.key_expires_at  := NOW() + INTERVAL '24 hours';
    NEW.expires_at      := COALESCE(NEW.expires_at, NOW() + INTERVAL '15 minutes');
    NEW.get_expires_at  := COALESCE(NEW.get_expires_at, NOW() + INTERVAL '24 hours');
  ELSIF NEW.plan = '7d' THEN
    NEW.is_unlimited    := FALSE;
    NEW.duration_hours  := 168;
    NEW.key_expires_at  := NOW() + INTERVAL '7 days';
    NEW.expires_at      := COALESCE(NEW.expires_at, NOW() + INTERVAL '15 minutes');
    NEW.get_expires_at  := COALESCE(NEW.get_expires_at, NOW() + INTERVAL '24 hours');
  ELSIF NEW.plan = '30d' THEN
    NEW.is_unlimited    := FALSE;
    NEW.duration_hours  := 720;
    NEW.key_expires_at  := NOW() + INTERVAL '30 days';
    NEW.expires_at      := COALESCE(NEW.expires_at, NOW() + INTERVAL '15 minutes');
    NEW.get_expires_at  := COALESCE(NEW.get_expires_at, NOW() + INTERVAL '24 hours');
  END IF;
  NEW.last_checked_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_expiry ON public.animula_keys;
CREATE TRIGGER trg_set_expiry 
  BEFORE INSERT ON public.animula_keys 
  FOR EACH ROW EXECUTE FUNCTION public.set_key_expiry();

-- ==============================================================================
-- Trigger Function: Max 1 Active Key Per Roblox Account
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.check_one_active_per_user()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.animula_keys
    WHERE roblox_id = NEW.roblox_id
      AND id != NEW.id
      AND state IN ('LOOT_COMPLETED', 'CLAIMED')
      AND (is_unlimited = TRUE OR key_expires_at > NOW())
  ) THEN
    RAISE EXCEPTION 'Roblox @% (ID %) already has active key (max 1). Wait expiry or use Dashboard.', NEW.roblox_username, NEW.roblox_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_one_active ON public.animula_keys;
CREATE TRIGGER trg_one_active 
  BEFORE INSERT OR UPDATE ON public.animula_keys 
  FOR EACH ROW EXECUTE FUNCTION public.check_one_active_per_user();

-- ==============================================================================
-- Function: Auto Expire Expired Keys & Stale Generate Links
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.auto_expire_keys()
RETURNS VOID AS $$
BEGIN
  UPDATE public.animula_keys
  SET state = 'EXPIRED', last_checked_at = NOW()
  WHERE state NOT IN ('CLAIMED', 'EXPIRED')
    AND is_unlimited = FALSE
    AND key_expires_at IS NOT NULL
    AND key_expires_at < NOW();

  UPDATE public.animula_keys
  SET state = 'EXPIRED', last_checked_at = NOW()
  WHERE state = 'CREATED'
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Cron Schedule (if pg_cron is enabled)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule('animula-auto-expire', '* * * * *', 'SELECT public.auto_expire_keys()');
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron not available; auto_expire will run via app server checks.';
END $$;

-- ==============================================================================
-- Function: Validate Key (Used by Web / Script Verification)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.is_key_valid(p_animula_key TEXT, p_roblox_id BIGINT)
RETURNS TABLE(valid BOOLEAN, reason TEXT, expires_at TIMESTAMPTZ) AS $$
DECLARE
  r RECORD;
BEGIN
  SELECT * INTO r FROM public.animula_keys WHERE animula_key = p_animula_key;
  IF NOT FOUND THEN 
    RETURN QUERY SELECT FALSE, 'NOT_FOUND'::TEXT, NULL::TIMESTAMPTZ; 
    RETURN; 
  END IF;

  IF r.roblox_id != p_roblox_id THEN 
    RETURN QUERY SELECT FALSE, 'ROBLOX_MISMATCH'::TEXT, r.key_expires_at; 
    RETURN; 
  END IF;

  IF r.state = 'EXPIRED' THEN 
    RETURN QUERY SELECT FALSE, 'EXPIRED'::TEXT, r.key_expires_at; 
    RETURN; 
  END IF;

  IF r.claimed AND r.state = 'CLAIMED' THEN
    IF r.is_unlimited = FALSE AND r.key_expires_at < NOW() THEN
      UPDATE public.animula_keys SET state = 'EXPIRED' WHERE id = r.id;
      RETURN QUERY SELECT FALSE, 'EXPIRED'::TEXT, r.key_expires_at; 
      RETURN;
    END IF;
    RETURN QUERY SELECT TRUE, 'VALID'::TEXT, r.key_expires_at; 
    RETURN;
  END IF;

  IF r.is_unlimited = FALSE AND r.key_expires_at < NOW() THEN
    UPDATE public.animula_keys SET state = 'EXPIRED' WHERE id = r.id;
    RETURN QUERY SELECT FALSE, 'EXPIRED'::TEXT, r.key_expires_at; 
    RETURN;
  END IF;

  IF r.state != 'CLAIMED' AND r.state != 'LOOT_COMPLETED' THEN
    RETURN QUERY SELECT FALSE, 'NOT_CLAIMED'::TEXT, r.key_expires_at; 
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'VALID'::TEXT, r.key_expires_at;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- Views: Active Keys & Statistics
-- ==============================================================================
CREATE OR REPLACE VIEW public.animula_active_keys AS
SELECT 
  id, 
  token, 
  get_token, 
  animula_key, 
  roblox_username, 
  roblox_id, 
  roblox_display_name, 
  plan, 
  is_unlimited, 
  duration_hours, 
  state, 
  created_at, 
  key_expires_at,
  CASE WHEN is_unlimited THEN 'Unlimited' ELSE (key_expires_at - NOW())::TEXT END AS time_left,
  claimed
FROM public.animula_keys
WHERE state NOT IN ('EXPIRED') AND (is_unlimited OR key_expires_at > NOW());

CREATE OR REPLACE VIEW public.animula_stats AS
SELECT
  COUNT(*)                                            AS total,
  COUNT(*) FILTER (WHERE state = 'CREATED')          AS created,
  COUNT(*) FILTER (WHERE state = 'LOOT_COMPLETED')   AS completed,
  COUNT(*) FILTER (WHERE claimed)                     AS claimed,
  COUNT(*) FILTER (WHERE state = 'EXPIRED')          AS expired,
  COUNT(*) FILTER (WHERE is_unlimited)                AS unlimited,
  COUNT(*) FILTER (WHERE plan = '24h')               AS daily,
  COUNT(DISTINCT roblox_id)                          AS unique_users
FROM public.animula_keys;

-- ==============================================================================
-- Security & Permissions (RLS)
-- ==============================================================================
ALTER TABLE public.animula_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all" ON public.animula_keys;
DROP POLICY IF EXISTS "anon_select" ON public.animula_keys;

REVOKE ALL ON public.animula_keys FROM anon, authenticated;
REVOKE ALL ON public.animula_active_keys FROM anon, authenticated;
REVOKE ALL ON public.animula_stats FROM anon, authenticated;

GRANT EXECUTE ON FUNCTION public.is_key_valid(TEXT, BIGINT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.auto_expire_keys() TO service_role;

