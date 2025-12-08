-- Dream Journal Database Schema
-- Run this in your Supabase SQL editor

-- ============================================
-- PROFILES TABLE
-- ============================================
create table if not exists public.profiles (
    id uuid references auth.users on delete cascade primary key,
    credits_remaining int not null default 3,
    subscription_tier text not null default 'free' check (subscription_tier in ('free', 'pro')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Profiles policies
create policy "Users can view own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Function to handle new user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id, credits_remaining, subscription_tier)
    values (new.id, 3, 'free');
    return new;
end;
$$;

-- Trigger to create profile on signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- ============================================
-- DREAMS TABLE
-- ============================================
create table if not exists public.dreams (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    title text,
    transcript text not null,
    themes text[] default '{}',
    emotions text[] default '{}',
    audio_path text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.dreams enable row level security;

-- Dreams policies
create policy "Users can view own dreams"
    on public.dreams for select
    using (auth.uid() = user_id);

create policy "Users can insert own dreams"
    on public.dreams for insert
    with check (auth.uid() = user_id);

create policy "Users can update own dreams"
    on public.dreams for update
    using (auth.uid() = user_id);

create policy "Users can delete own dreams"
    on public.dreams for delete
    using (auth.uid() = user_id);

-- Index for faster queries
create index if not exists dreams_user_id_idx on public.dreams(user_id);
create index if not exists dreams_created_at_idx on public.dreams(created_at desc);

-- ============================================
-- VIDEO JOBS TABLE
-- ============================================
create table if not exists public.video_jobs (
    id uuid primary key default gen_random_uuid(),
    dream_id uuid references public.dreams(id) on delete cascade not null,
    user_id uuid references public.profiles(id) on delete cascade not null,
    status text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
    replicate_id text,
    video_path text,
    error_message text,
    created_at timestamptz not null default now(),
    completed_at timestamptz,
    updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.video_jobs enable row level security;

-- Video jobs policies
create policy "Users can view own video jobs"
    on public.video_jobs for select
    using (auth.uid() = user_id);

create policy "Users can insert own video jobs"
    on public.video_jobs for insert
    with check (auth.uid() = user_id);

create policy "Users can update own video jobs"
    on public.video_jobs for update
    using (auth.uid() = user_id);

-- Index for faster queries
create index if not exists video_jobs_dream_id_idx on public.video_jobs(dream_id);
create index if not exists video_jobs_user_id_idx on public.video_jobs(user_id);
create index if not exists video_jobs_replicate_id_idx on public.video_jobs(replicate_id);

-- ============================================
-- STORAGE BUCKETS
-- ============================================

-- Create buckets (run these separately if needed)
-- insert into storage.buckets (id, name, public) values ('dream-audio', 'dream-audio', false);
-- insert into storage.buckets (id, name, public) values ('dream-videos', 'dream-videos', false);

-- Storage policies for dream-audio bucket
create policy "Users can upload own audio"
    on storage.objects for insert
    with check (
        bucket_id = 'dream-audio' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

create policy "Users can view own audio"
    on storage.objects for select
    using (
        bucket_id = 'dream-audio' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

create policy "Users can delete own audio"
    on storage.objects for delete
    using (
        bucket_id = 'dream-audio' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Storage policies for dream-videos bucket
create policy "Users can view own videos"
    on storage.objects for select
    using (
        bucket_id = 'dream-videos' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

create policy "Service role can upload videos"
    on storage.objects for insert
    with check (bucket_id = 'dream-videos');

create policy "Users can delete own videos"
    on storage.objects for delete
    using (
        bucket_id = 'dream-videos' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================
-- UPDATED_AT TRIGGERS
-- ============================================

create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger profiles_updated_at
    before update on public.profiles
    for each row execute procedure public.handle_updated_at();

create trigger dreams_updated_at
    before update on public.dreams
    for each row execute procedure public.handle_updated_at();

create trigger video_jobs_updated_at
    before update on public.video_jobs
    for each row execute procedure public.handle_updated_at();

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to decrement credits
create or replace function public.decrement_credits(user_uuid uuid)
returns void
language plpgsql
security definer
as $$
begin
    update public.profiles
    set credits_remaining = credits_remaining - 1
    where id = user_uuid
    and subscription_tier = 'free'
    and credits_remaining > 0;
end;
$$;

-- Function to check if user can generate video
create or replace function public.can_generate_video(user_uuid uuid)
returns boolean
language plpgsql
security definer
as $$
declare
    user_profile public.profiles%rowtype;
begin
    select * into user_profile from public.profiles where id = user_uuid;

    if user_profile.subscription_tier = 'pro' then
        return true;
    end if;

    return user_profile.credits_remaining > 0;
end;
$$;
