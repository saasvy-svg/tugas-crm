-- ==============================================================================
-- VYLOGIX CRM — SUPABASE STORAGE SETUP (FIXED)
-- Project: db-crm (https://bitqzakkvyvzvwnuqhtj.supabase.co)
-- ==============================================================================

-- 1. BUAT STORAGE BUCKET: "assets" (Public Bucket)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'assets',
    'assets',
    true,
    52428800, -- Batas ukuran file 50 MB
    NULL      -- Mengizinkan semua tipe file
)
ON CONFLICT (id) DO UPDATE SET 
    public = true,
    file_size_limit = 52428800;

-- 2. POLICY: BACA FILE PUBLIK (Siapa saja bisa lihat logo, QRIS, & aset publik)
DROP POLICY IF EXISTS "Public Read Assets" ON storage.objects;
CREATE POLICY "Public Read Assets"
ON storage.objects FOR SELECT
USING (bucket_id = 'assets');

-- 3. POLICY: UPLOAD FILE (User login: Admin, Staf, Klien bisa upload)
DROP POLICY IF EXISTS "Authenticated Users Upload Assets" ON storage.objects;
CREATE POLICY "Authenticated Users Upload Assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'assets');

-- 4. POLICY: UPDATE FILE (Bisa timpa / ganti file)
DROP POLICY IF EXISTS "Authenticated Users Update Assets" ON storage.objects;
CREATE POLICY "Authenticated Users Update Assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'assets');

-- 5. POLICY: HAPUS FILE (Bisa hapus aset yang sudah tidak dipakai)
DROP POLICY IF EXISTS "Authenticated Users Delete Assets" ON storage.objects;
CREATE POLICY "Authenticated Users Delete Assets"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'assets');
