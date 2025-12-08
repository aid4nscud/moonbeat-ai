-- Pro User Monthly Quota System
-- Adds configurable monthly video generation limits for Pro users

-- ============================================
-- APP SETTINGS TABLE
-- ============================================
create table if not exists public.app_settings (
    key text primary key,
    value jsonb not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Enable RLS (only service role should access)
alter table public.app_settings enable row level security;

-- Insert default monthly quota (30 videos/month = 1/day)
insert into public.app_settings (key, value) values
    ('pro_monthly_quota', '{"limit": 30}'::jsonb)
on conflict (key) do nothing;

-- Trigger for app_settings updated_at
create trigger app_settings_updated_at
    before update on public.app_settings
    for each row execute procedure public.handle_updated_at();

-- ============================================
-- MONTHLY USAGE TRACKING FUNCTIONS
-- ============================================

-- Function to get monthly video count for a user
create or replace function public.get_monthly_video_count(
    user_uuid uuid,
    target_month timestamptz default now()
)
returns integer
language plpgsql
security definer
as $$
declare
    month_start timestamptz;
    month_end timestamptz;
    video_count integer;
begin
    month_start := date_trunc('month', target_month at time zone 'UTC');
    month_end := month_start + interval '1 month';

    select count(*)::integer into video_count
    from public.video_jobs
    where user_id = user_uuid
      and created_at >= month_start
      and created_at < month_end
      and status in ('pending', 'processing', 'completed');
      -- Count pending/processing to prevent race conditions

    return video_count;
end;
$$;

-- Function to check if Pro user can generate video (returns detailed status)
create or replace function public.can_pro_user_generate_video(user_uuid uuid)
returns table(
    can_generate boolean,
    videos_used integer,
    videos_remaining integer,
    quota_limit integer,
    resets_at timestamptz
)
language plpgsql
security definer
as $$
declare
    user_tier text;
    current_usage integer;
    monthly_limit integer;
    next_month timestamptz;
begin
    -- Get user tier
    select subscription_tier into user_tier
    from public.profiles
    where id = user_uuid;

    -- Free users use different system
    if user_tier = 'free' or user_tier is null then
        return query select false, 0, 0, 0, now();
        return;
    end if;

    -- Get configurable limit (default 30)
    select coalesce((value->>'limit')::integer, 30) into monthly_limit
    from public.app_settings
    where key = 'pro_monthly_quota';

    if monthly_limit is null then
        monthly_limit := 30;
    end if;

    -- Get current usage
    current_usage := public.get_monthly_video_count(user_uuid);

    -- Calculate reset date (first of next month UTC)
    next_month := date_trunc('month', now() at time zone 'UTC') + interval '1 month';

    -- Return results
    return query select
        current_usage < monthly_limit,
        current_usage,
        greatest(0, monthly_limit - current_usage),
        monthly_limit,
        next_month;
end;
$$;

-- Update main can_generate_video function to include Pro quota check
create or replace function public.can_generate_video(user_uuid uuid)
returns boolean
language plpgsql
security definer
as $$
declare
    user_profile public.profiles%rowtype;
    pro_status record;
begin
    select * into user_profile from public.profiles where id = user_uuid;

    if user_profile.subscription_tier = 'pro' then
        -- Use quota-based check for Pro users
        select * into pro_status from public.can_pro_user_generate_video(user_uuid);
        return pro_status.can_generate;
    end if;

    -- Free users: use existing credits system
    return user_profile.credits_remaining > 0;
end;
$$;

-- ============================================
-- PERFORMANCE INDEX
-- ============================================

-- Index for efficient monthly usage queries
create index if not exists video_jobs_user_monthly_idx
on public.video_jobs(user_id, created_at)
where status in ('pending', 'processing', 'completed');
