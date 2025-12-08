-- Add display_name column to profiles table
-- This allows users to have a personalized greeting in the app

-- Add the column
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS display_name text;

-- Update the handle_new_user function to extract display name from auth metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    user_display_name text;
BEGIN
    -- Try to get display name from Apple Sign In metadata
    -- Apple provides 'full_name' in user_metadata
    user_display_name := new.raw_user_meta_data->>'full_name';

    -- If no full_name, try 'name' field
    IF user_display_name IS NULL THEN
        user_display_name := new.raw_user_meta_data->>'name';
    END IF;

    -- Insert the profile with display name
    INSERT INTO public.profiles (id, credits_remaining, subscription_tier, display_name)
    VALUES (new.id, 3, 'free', user_display_name);

    RETURN new;
END;
$$;

-- For existing users, we could try to populate display_name from auth.users metadata
-- This is a one-time update for users who already exist
UPDATE public.profiles p
SET display_name = COALESCE(
    u.raw_user_meta_data->>'full_name',
    u.raw_user_meta_data->>'name'
)
FROM auth.users u
WHERE p.id = u.id
AND p.display_name IS NULL;
