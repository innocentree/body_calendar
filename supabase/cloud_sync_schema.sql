create extension if not exists pgcrypto;

create table if not exists public.user_sync_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  provider text,
  device_id text,
  backup_version integer not null default 1,
  summary jsonb not null default '{}'::jsonb,
  payload jsonb not null,
  synced_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.touch_user_sync_snapshots_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_user_sync_snapshots_updated_at on public.user_sync_snapshots;

create trigger trg_user_sync_snapshots_updated_at
before update on public.user_sync_snapshots
for each row
execute function public.touch_user_sync_snapshots_updated_at();

alter table public.user_sync_snapshots enable row level security;

drop policy if exists "Users can read own sync snapshot" on public.user_sync_snapshots;
create policy "Users can read own sync snapshot"
on public.user_sync_snapshots
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own sync snapshot" on public.user_sync_snapshots;
create policy "Users can insert own sync snapshot"
on public.user_sync_snapshots
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own sync snapshot" on public.user_sync_snapshots;
create policy "Users can update own sync snapshot"
on public.user_sync_snapshots
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own sync snapshot" on public.user_sync_snapshots;
create policy "Users can delete own sync snapshot"
on public.user_sync_snapshots
for delete
to authenticated
using (auth.uid() = user_id);
