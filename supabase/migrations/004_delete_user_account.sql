-- Delete User Account RPC Function
-- Allows users to permanently delete their account and all associated data
-- Called by AuthService.deleteAccount()
-- Required for GDPR/CCPA compliance and Apple App Store guidelines

-- First, delete user's storage files
create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    user_id uuid := auth.uid();
begin
    -- Verify user is authenticated
    if user_id is null then
        raise exception 'Not authenticated';
    end if;

    -- Delete audio files from storage
    delete from storage.objects
    where bucket_id = 'dream-audio'
    and (storage.foldername(name))[1] = user_id::text;

    -- Delete video files from storage
    delete from storage.objects
    where bucket_id = 'dream-videos'
    and (storage.foldername(name))[1] = user_id::text;

    -- Delete video jobs (cascade will be handled by FK, but explicit for safety)
    delete from public.video_jobs
    where dream_id in (select id from public.dreams where user_id = user_id);

    -- Delete dreams
    delete from public.dreams
    where user_id = user_id;

    -- Delete profile
    delete from public.profiles
    where id = user_id;

    -- Finally, delete the auth user (this must be last)
    -- Note: This requires the function to be security definer
    delete from auth.users
    where id = user_id;
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.delete_user_account() to authenticated;
