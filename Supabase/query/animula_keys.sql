-- Animula Official - Supabase Schema PRO 24/7 - Generate Key, Roblox Check, Max 1, Time, Unlimited, Daily, Auto Expiry
-- Project: eiykqbkfljqxwfqdffpo - Run at https://supabase.com/dashboard/project/eiykqbkfljqxwfqdffpo/sql
-- Also works via VS Code Supabase extension SQL Editor

-- Extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pg_cron" with schema pg_catalog;

-- Main keys table - 24/7, anti-error, with Roblox binding max 1
create table if not exists public.animula_keys (
  id uuid primary key default uuid_generate_v4(),
  token text not null unique, -- 50 char generate token /web/generetekey/XXXX
  get_token text unique, -- 50 char getkey token /web/getkey/XXXX (HMAC)
  animula_key text unique, -- Animula-fs-XXXXXXXXXXXXXXXXXXXX (20)
  roblox_username text not null,
  roblox_id bigint not null,
  roblox_display_name text,
  roblox_avatar text,
  plan text not null default '24h' check (plan in ('24h','7d','30d','lifetime')),
  is_unlimited boolean not null default false, -- true for lifetime
  duration_hours int, -- 24 for 24h, 168 for 7d, 720 for 30d, null for unlimited
  state text not null default 'CREATED' check (state in ('CREATED','LOOT_STARTED','LOOT_COMPLETED','CLAIMED','EXPIRED')),
  created_at timestamptz not null default now(),
  loot_started_at timestamptz,
  loot_completed_at timestamptz,
  expires_at timestamptz, -- generate link expiry 15m, key expiry depends on plan
  get_expires_at timestamptz, -- getkey link expiry
  key_expires_at timestamptz, -- actual key expiry (for daily/unlimited). null = unlimited
  claimed boolean not null default false,
  claimed_at timestamptz,
  last_checked_at timestamptz default now(),
  last_used_at timestamptz,
  use_count int not null default 0,
  ip_hash text,
  user_agent text,
  -- constraints
  constraint token_format check (token ~ '^[A-Za-z0-9]{50}$'),
  constraint get_token_format check (get_token is null or get_token ~ '^[A-Za-z0-9]{50}$'),
  constraint animula_key_format check (animula_key is null or animula_key ~ '^Animula-fs-[A-Za-z0-9]{20}$'),
  constraint roblox_username_format check (roblox_username ~ '^[A-Za-z0-9_]{3,20}$'),
  constraint duration_check check ((is_unlimited = true and duration_hours is null and key_expires_at is null) or (is_unlimited = false and duration_hours is not null))
);

-- Indexes for 24/7 fast lookup (no error under load)
create index if not exists idx_keys_token on public.animula_keys(token);
create index if not exists idx_keys_get_token on public.animula_keys(get_token);
create index if not exists idx_keys_animula on public.animula_keys(animula_key);
create index if not exists idx_keys_roblox_id on public.animula_keys(roblox_id);
create index if not exists idx_keys_roblox_username on public.animula_keys(roblox_username);
create index if not exists idx_keys_state on public.animula_keys(state);
create index if not exists idx_keys_plan on public.animula_keys(plan);
create index if not exists idx_keys_created_at on public.animula_keys(created_at);
create index if not exists idx_keys_expires_at on public.animula_keys(expires_at);
create index if not exists idx_keys_key_expires_at on public.animula_keys(key_expires_at);
create index if not exists idx_keys_claimed on public.animula_keys(claimed);
-- partial index for active keys (max 1 check, 24/7)
create index if not exists idx_keys_active_per_user on public.animula_keys(roblox_id, expires_at) where claimed = false and state != 'CLAIMED' and state != 'EXPIRED';

-- Function: set duration & expiry based on plan (called on insert)
create or replace function public.set_key_expiry()
returns trigger as $$
begin
  -- set is_unlimited & duration
  if new.plan = 'lifetime' then
    new.is_unlimited := true;
    new.duration_hours := null;
    new.key_expires_at := null; -- unlimited never expires
    new.expires_at := coalesce(new.expires_at, now() + interval '15 minutes');
    new.get_expires_at := coalesce(new.get_expires_at, now() + interval '24 hours');
  elsif new.plan = '24h' then
    new.is_unlimited := false;
    new.duration_hours := 24;
    new.key_expires_at := now() + interval '24 hours';
    new.expires_at := coalesce(new.expires_at, now() + interval '15 minutes');
    new.get_expires_at := coalesce(new.get_expires_at, now() + interval '24 hours');
  elsif new.plan = '7d' then
    new.is_unlimited := false;
    new.duration_hours := 168;
    new.key_expires_at := now() + interval '7 days';
    new.expires_at := coalesce(new.expires_at, now() + interval '15 minutes');
    new.get_expires_at := coalesce(new.get_expires_at, now() + interval '24 hours');
  elsif new.plan = '30d' then
    new.is_unlimited := false;
    new.duration_hours := 720;
    new.key_expires_at := now() + interval '30 days';
    new.expires_at := coalesce(new.expires_at, now() + interval '15 minutes');
    new.get_expires_at := coalesce(new.get_expires_at, now() + interval '24 hours');
  end if;
  new.last_checked_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_set_expiry on public.animula_keys;
create trigger trg_set_expiry before insert on public.animula_keys for each row execute function public.set_key_expiry();

-- Function: max 1 active per Roblox account (check before insert)
create or replace function public.check_one_active_per_user()
returns trigger as $$
begin
  if exists (
    select 1 from public.animula_keys
    where roblox_id = new.roblox_id
      and claimed = false
      and state not in ('CLAIMED','EXPIRED')
      and (is_unlimited = true or key_expires_at > now())
      and id != new.id
  ) then
    raise exception 'Roblox @% (ID %) already has active key (max 1). Wait expiry or use Dashboard.', new.roblox_username, new.roblox_id;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_one_active on public.animula_keys;
create trigger trg_one_active before insert or update on public.animula_keys for each row execute function public.check_one_active_per_user();

-- Function: auto check if time expires -> set EXPIRED (called by cron & on read)
create or replace function public.auto_expire_keys()
returns void as $$
begin
  update public.animula_keys
  set state = 'EXPIRED', last_checked_at = now()
  where state not in ('CLAIMED','EXPIRED')
    and is_unlimited = false
    and key_expires_at is not null
    and key_expires_at < now();
  -- also expire generate links 15m
  update public.animula_keys
  set state = 'EXPIRED', last_checked_at = now()
  where state = 'CREATED'
    and expires_at < now();
end;
$$ language plpgsql;

-- Cron 24/7 auto check every minute (if pg_cron available, else call manually)
do $$
begin
  if exists (select 1 from pg_extension where extname='pg_cron') then
    perform cron.schedule('animula-auto-expire', '* * * * *', 'select public.auto_expire_keys()');
  end if;
exception when others then
  raise notice 'pg_cron not available, auto_expire must be called via app (Web/server checks on validate)';
end $$;

-- Function: check if key is valid (for Web/server 24/7 check)
create or replace function public.is_key_valid(p_animula_key text, p_roblox_id bigint)
returns table(valid boolean, reason text, expires_at timestamptz) as $$
declare
  r record;
begin
  select * into r from public.animula_keys where animula_key = p_animula_key;
  if not found then return query select false, 'NOT_FOUND'::text, null::timestamptz; return; end if;
  if r.roblox_id != p_roblox_id then return query select false, 'ROBLOX_MISMATCH'::text, r.key_expires_at; return; end if;
  if r.state = 'EXPIRED' then return query select false, 'EXPIRED'::text, r.key_expires_at; return; end if;
  if r.claimed and r.state = 'CLAIMED' then
    -- claimed keys still valid until key_expires_at unless unlimited
    if r.is_unlimited = false and r.key_expires_at < now() then
      update public.animula_keys set state='EXPIRED' where id=r.id;
      return query select false, 'EXPIRED'::text, r.key_expires_at; return;
    end if;
    return query select true, 'VALID'::text, r.key_expires_at; return;
  end if;
  if r.is_unlimited = false and r.key_expires_at < now() then
    update public.animula_keys set state='EXPIRED' where id=r.id;
    return query select false, 'EXPIRED'::text, r.key_expires_at; return;
  end if;
  -- not yet claimed but completed loot -> still need claim
  if r.state != 'CLAIMED' and r.state != 'LOOT_COMPLETED' then
    return query select false, 'NOT_CLAIMED'::text, r.key_expires_at; return;
  end if;
  return query select true, 'VALID'::text, r.key_expires_at;
end;
$$ language plpgsql;

-- View: active keys (for 24/7 dashboard)
create or replace view public.animula_active_keys as
select id, token, get_token, animula_key, roblox_username, roblox_id, roblox_display_name, plan, is_unlimited, duration_hours, state, created_at, key_expires_at,
  case when is_unlimited then 'Unlimited' else (key_expires_at - now())::text end as time_left,
  claimed
from public.animula_keys
where state not in ('EXPIRED') and (is_unlimited or key_expires_at > now());

-- View: stats 24/7
create or replace view public.animula_stats as
select
  count(*) as total,
  count(*) filter (where state='CREATED') as created,
  count(*) filter (where state='LOOT_COMPLETED') as completed,
  count(*) filter (where claimed) as claimed,
  count(*) filter (where state='EXPIRED') as expired,
  count(*) filter (where is_unlimited) as unlimited,
  count(*) filter (where plan='24h') as daily,
  count(distinct roblox_id) as unique_users
from public.animula_keys;

-- RLS off for anon (Web uses anon key)
alter table public.animula_keys disable row level security;
grant all on public.animula_keys to anon, authenticated, service_role;
grant all on public.animula_active_keys to anon, authenticated;
grant all on public.animula_stats to anon, authenticated;
grant execute on function public.auto_expire_keys() to anon, authenticated;
grant execute on function public.is_key_valid(text,bigint) to anon, authenticated;

-- Manual 24/7 check helper: call select public.auto_expire_keys(); before every validate (Web/server already does time check)
