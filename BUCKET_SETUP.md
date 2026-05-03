# Create Profiles Bucket in Supabase

Since you already have Supabase configured and working for `gym-stories` and `gym-courses`, you just need to create the `gym-profiles` bucket for profile images.

## Quick Setup (2 minutes)

1. **Go to your Supabase Dashboard**: https://app.supabase.com/project/smltgpsrrfqqhfgqfczg
2. **Navigate to Storage**:
   - Click "Storage" in the left sidebar
3. **Create the profiles bucket**:
   - Click "New bucket"
   - Name: `gym-profiles`
   - Make it **Public** (check the public option)
   - Click "Create bucket"

## Alternative: SQL Command

If you prefer, you can run this SQL command in the Supabase SQL Editor:

```sql
-- Create the gym-profiles bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('gym-profiles', 'gym-profiles', true);
```

## Verify Setup

After creating the bucket, try uploading a profile image again. You should see these logs in your Flutter console:

```
🔧 Checking Supabase configuration...
📍 URL: https://smltgpsrrfqqhfgqfczg.supabase.co
🔑 Key: eyJhbGciOiJIUzI1NiIs...
✅ Configured: true
🚀 Initializing Supabase...
✅ Supabase initialized successfully!
```

## Bucket Policies (Optional)

For extra security, you can add these RLS policies to the `gym-profiles` bucket:

```sql
-- Allow users to upload their own profile images
CREATE POLICY "Users can upload profile images" 
ON storage.objects FOR INSERT 
WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);

-- Allow anyone to view profile images  
CREATE POLICY "Profile images are publicly accessible" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'gym-profiles');
```

But since you're making it a public bucket, the images will be accessible to everyone by default.