class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://smltgpsrrfqqhfgqfczg.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtbHRncHNycmZxcWhmZ3FmY3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2NDkzMzksImV4cCI6MjA3NzIyNTMzOX0.t0vLvgd6o2qpLuxOmgLJQu4bITkPOsKachd8fZuKLE8';
  
  // Storage bucket for profile images
  static const String profilesBucket = 'gym-profiles';
  static const String feedBucket = 'gym-feed';

  
  // Check if Supabase is properly configured
  static bool get isConfigured {
    return supabaseUrl != 'https://your-project-id.supabase.co' && 
           supabaseAnonKey != 'your-anon-public-key' &&
           supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty;
  }
}

// Setup Instructions:
// 1. Create a Supabase project at https://supabase.com
// 2. Go to Settings > API to get your URL and anon key
// 3. Create a storage bucket called 'profiles' in Storage
// 4. Set the bucket to public or add these RLS policies:
/*
-- Allow users to upload their own profile images
CREATE POLICY "Users can upload profile images" 
ON storage.objects FOR INSERT 
WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);

-- Allow anyone to view profile images  
CREATE POLICY "Profile images are publicly accessible" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'profiles');
*/