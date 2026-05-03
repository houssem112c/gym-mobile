# Supabase Setup Guide

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in or create an account
3. Click "New Project" 
4. Choose your organization
5. Fill in:
   - Name: `gym-mobile-app` (or any name you prefer)
   - Database Password: Create a strong password
   - Region: Choose closest to your users
6. Click "Create new project"

## Step 2: Get Your Project Credentials

1. Wait for your project to be created (2-3 minutes)
2. Go to **Settings** > **API** in the left sidebar
3. Copy the following values:
   - **Project URL**: `https://xyzcompany.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Step 3: Create Storage Bucket

1. Go to **Storage** in the left sidebar
2. Click "Create a new bucket"
3. Fill in:
   - Name: `profiles`
   - Public bucket: ✅ **Enable** (so profile images are publicly accessible)
4. Click "Create bucket"

## Step 4: Set Up Row Level Security (Optional but recommended)

1. Go to **Storage** > **Settings** > **Policies**
2. For the `profiles` bucket, click "Add policy"
3. Add these policies:

### Allow Upload Policy:
- **Policy name**: `Users can upload profile images`
- **Operation**: INSERT
- **Target roles**: `authenticated`
- **USING expression**: `auth.uid()::text = (storage.foldername(name))[1]`

### Allow Read Policy:
- **Policy name**: `Profile images are publicly accessible`
- **Operation**: SELECT  
- **Target roles**: `public`
- **USING expression**: `bucket_id = 'profiles'`

## Step 5: Update Your Flutter App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
  
  static const String profilesBucket = 'profiles';
  
  static bool get isConfigured {
    return supabaseUrl != 'https://your-project-id.supabase.co' && 
           supabaseAnonKey != 'your-anon-public-key' &&
           supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty;
  }
}
```

## Step 6: Test the Setup

1. Run your Flutter app
2. Go to the Profile screen
3. Try uploading a profile image
4. Check the Supabase Storage dashboard to see if the image was uploaded

## Troubleshooting

### Images not uploading:
- Check that the `profiles` bucket exists and is public
- Verify your URL and API key are correct
- Check browser console for CORS errors

### Permission denied:
- Make sure the bucket is set to public
- Check RLS policies are set correctly

### Connection errors:
- Verify your internet connection
- Check that your Supabase project is active (not paused)

## What happens without Supabase?

If you don't set up Supabase, the app will still work but:
- Profile images won't be uploaded to cloud storage
- Images will only be stored locally during the session
- You'll see warning messages in the console

To skip image upload entirely, you can modify `ProfileService.uploadProfileImage()` to always return a placeholder URL.