-- ==============================================================================
-- VYLOGIX CRM — SUPABASE STORAGE SETUP
-- Project: https://bitqzakkvyvzvwnuqhtj.supabase.co (db-crm)
-- Eksekusi file ini di SQL Editor pada Supabase Dashboard: db-crm
-- ==============================================================================

-- 1. BUAT STORAGE BUCKET: "assets" (Public Bucket)
-- Bucket ini menampung logo agensi, gambar QRIS, file proyek/desain, dan bukti bayar.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'assets',
    'assets',
    true,
    52428800, -- Batas ukuran file 50 MB
    NULL      -- Mengizinkan semua jenis file (PNG, JPG, PDF, ZIP, AI, PSD, dll)
)
ON CONFLICT (id) DO UPDATE SET 
    public = true,
    file_size_limit = 52428800;

-- 2. AKTIFKAN RLS PADA STORAGE OBJECTS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. POLICY: AKSES BACA PUBLIK (PUBLIC READ)
-- Siapa saja (termasuk klien via browser) bisa melihat preview logo, QRIS, dan aset publik
DROP POLICY IF EXISTS "Public Read Assets" ON storage.objects;
CREATE POLICY "Public Read Assets"
ON storage.objects FOR SELECT
USING (bucket_id = 'assets');

-- 4. POLICY: AKSES UPLOAD (AUTHENTICATED INSERT)
-- User yang sudah login (Admin, Staf, maupun Klien) diizinkan mengunggah file
DROP POLICY IF EXISTS "Authenticated Users Upload Assets" ON storage.objects;
CREATE POLICY "Authenticated Users Upload Assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'assets');

-- 5. POLICY: AKSES UPDATE / TIMPA FILE (AUTHENTICATED UPDATE)
DROP POLICY IF EXISTS "Authenticated Users Update Assets" ON storage.objects;
CREATE POLICY "Authenticated Users Update Assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'assets');

-- 6. POLICY: AKSES HAPUS FILE (AUTHENTICATED DELETE)
DROP POLICY IF EXISTS "Authenticated Users Delete Assets" ON storage.objects;
CREATE POLICY "Authenticated Users Delete Assets"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'assets');

-- ==============================================================================
-- SELESAI. Storage Bucket "assets" kini aktif dan siap menerima upload file!
-- ==============================================================================
