-- ==============================================================================
-- VYLOGIX CRM — DATA PLANE SCHEMA (DATABASE 2: db-crm)
-- Project: https://bitqzakkvyvzvwnuqhtj.supabase.co
-- Tujuan: Database Operasional Multi-Tenant (Agensi, Tim Staff, Proyek & Klien)
-- Versi: Clean & Pure Architecture (Bebas dari Patch Lama & Bebas Super Admin)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 2. TABEL ORGANIZATIONS (Tenant Agensi yang terdaftar)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organizations (
    id                      UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    name                    TEXT        NOT NULL,
    slug                    TEXT        UNIQUE,
    is_active               BOOLEAN     DEFAULT true,
    auto_suspend            BOOLEAN     DEFAULT false,
    license_expires_at      TIMESTAMPTZ DEFAULT NULL,
    tagline                 TEXT        DEFAULT NULL,
    logo_url                TEXT        DEFAULT NULL,
    webhook_url             TEXT        DEFAULT NULL,
    log_retention_days      INTEGER     DEFAULT 30,
    whatsapp_number         TEXT        DEFAULT NULL,
    industry_type           TEXT        DEFAULT 'DIGITAL',
    qris_image_url          TEXT        DEFAULT NULL,
    module_digital          BOOLEAN     DEFAULT true,
    module_physical         BOOLEAN     DEFAULT false,
    custom_asset_categories TEXT[]      DEFAULT ARRAY['Logo & Branding', 'Font & Tipografi', 'Desain Siap Cetak', 'Dokumen & Copywriting', 'Gambar Konten Web/App', 'Lainnya']::TEXT[],
    monthly_sales_target    NUMERIC     DEFAULT 0,
    created_at              TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ------------------------------------------------------------------------------
-- 3. TABEL PROFILES (Pengguna: Admin Agensi, Staff, & Klien)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id              UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email           TEXT        NOT NULL,
    full_name       TEXT,
    role            TEXT        DEFAULT 'client',
    organization_id UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    whatsapp_number TEXT        DEFAULT NULL,
    address         TEXT        DEFAULT NULL,
    supplier_goods  TEXT        DEFAULT NULL,
    created_at      TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ------------------------------------------------------------------------------
-- 4. DYNAMIC RBAC (Roles & Permissions)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    slug TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS permissions (
    slug        TEXT PRIMARY KEY,
    description TEXT
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_slug       TEXT REFERENCES roles(slug) ON DELETE CASCADE,
    permission_slug TEXT REFERENCES permissions(slug) ON DELETE CASCADE,
    PRIMARY KEY (role_slug, permission_slug)
);

-- Inisialisasi Data Roles Operasional Agensi (Super Admin tidak ada di sini)
INSERT INTO roles (slug, name) VALUES 
    ('admin', 'Agency Admin (Owner/Manager)'),
    ('staff_ops', 'Staff Operasional / PM'),
    ('staff_finance', 'Staff Keuangan (Finance)'),
    ('staff_digital', 'Staff Digital (Programmer/Desainer Web)'),
    ('staff_cs', 'Staff Customer Service / Kasir'),
    ('staff_design', 'Staff Desainer Grafis & Percetakan'),
    ('staff_production', 'Tim Mesin Cetak & Produksi Fisik'),
    ('staff_warehouse', 'Admin Gudang & Stok'),
    ('staff_shipping', 'Tim Packing & Pengiriman'),
    ('client', 'Klien / Pelanggan')
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name;

-- Inisialisasi Master Permissions
INSERT INTO permissions (slug, description) VALUES
    ('projects.read', 'Bisa melihat daftar proyek agensi'),
    ('projects.manage', 'Bisa membuat, edit, dan kelola status proyek'),
    ('finance.read', 'Bisa melihat laporan keuangan & invoice'),
    ('finance.manage', 'Bisa membuat invoice & mencatat mutasi kas'),
    ('production.read', 'Bisa melihat antrean mesin produksi fisik'),
    ('production.manage', 'Bisa update status pengerjaan mesin produksi'),
    ('warehouse.read', 'Bisa melihat stok barang & bahan di gudang'),
    ('warehouse.manage', 'Bisa menambah & memutasi stok barang gudang'),
    ('packing.read', 'Bisa melihat antrean packing barang siap kirim'),
    ('packing.manage', 'Bisa update status packing & quality check'),
    ('shipping.read', 'Bisa melihat pesanan siap dikirim ke kurir'),
    ('shipping.manage', 'Bisa menginput nomor resi & update kurir'),
    ('digital_tasks.read', 'Bisa melihat penugasan task digital'),
    ('digital_tasks.manage', 'Bisa mengubah progress & upload file digital'),
    ('design.read', 'Bisa melihat antrean brief desain fisik'),
    ('design.manage', 'Bisa upload file cetak dan konfirmasi ke produksi'),
    ('sheets.configure', 'Bisa mengatur sinkronisasi Google Sheets'),
    ('sheets.export', 'Bisa melakukan ekspor manual data ke Google Sheets')
ON CONFLICT (slug) DO UPDATE SET description = EXCLUDED.description;

-- Pemetaan Role ke Permissions
INSERT INTO role_permissions (role_slug, permission_slug) VALUES
    -- Admin: Akses Penuh Semua Modul Operasional Agensi
    ('admin', 'projects.read'), ('admin', 'projects.manage'),
    ('admin', 'finance.read'), ('admin', 'finance.manage'),
    ('admin', 'production.read'), ('admin', 'production.manage'),
    ('admin', 'warehouse.read'), ('admin', 'warehouse.manage'),
    ('admin', 'packing.read'), ('admin', 'packing.manage'),
    ('admin', 'shipping.read'), ('admin', 'shipping.manage'),
    ('admin', 'digital_tasks.read'), ('admin', 'digital_tasks.manage'),
    ('admin', 'design.read'), ('admin', 'design.manage'),
    ('admin', 'sheets.configure'), ('admin', 'sheets.export'),

    -- Staff Operasional / Project Manager
    ('staff_ops', 'projects.read'), ('staff_ops', 'projects.manage'),
    ('staff_ops', 'production.read'), ('staff_ops', 'packing.read'), 
    ('staff_ops', 'shipping.read'), ('staff_ops', 'digital_tasks.read'),
    ('staff_ops', 'warehouse.read'), ('staff_ops', 'design.read'),

    -- Staff Keuangan
    ('staff_finance', 'finance.read'), ('staff_finance', 'finance.manage'),
    ('staff_finance', 'projects.read'),

    -- Staff Digital (Programmer / Web Designer)
    ('staff_digital', 'digital_tasks.read'), ('staff_digital', 'digital_tasks.manage'), 
    ('staff_digital', 'projects.read'),
    
    -- Staff CS / Kasir
    ('staff_cs', 'finance.read'), ('staff_cs', 'finance.manage'), 
    ('staff_cs', 'projects.read'), ('staff_cs', 'projects.manage'), 
    ('staff_cs', 'warehouse.read'),

    -- Staff Desain Fisik
    ('staff_design', 'design.read'), ('staff_design', 'design.manage'), 
    ('staff_design', 'projects.read'),

    -- Staff Produksi & Operator Mesin
    ('staff_production', 'production.read'), ('staff_production', 'production.manage'),

    -- Staff Gudang
    ('staff_warehouse', 'warehouse.read'), ('staff_warehouse', 'warehouse.manage'),

    -- Staff Packing & Pengiriman
    ('staff_shipping', 'projects.read'), ('staff_shipping', 'packing.read'), 
    ('staff_shipping', 'packing.manage'), ('staff_shipping', 'shipping.read'), 
    ('staff_shipping', 'shipping.manage')
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------------------------
-- 5. FUNGSI TRIGGER & HELPER RBAC
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        new.id,
        new.email,
        new.raw_user_meta_data ->> 'full_name',
        COALESCE(new.raw_user_meta_data ->> 'role', 'client')
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE OR REPLACE FUNCTION public.has_permission(p_user_id UUID, p_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_role TEXT;
BEGIN
  SELECT role INTO v_role FROM profiles WHERE id = p_user_id LIMIT 1;
  IF v_role = 'admin' THEN RETURN true; END IF;
  RETURN EXISTS (
    SELECT 1 FROM role_permissions
    WHERE role_slug = v_role AND permission_slug = p_permission
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_my_org_id()
RETURNS UUID AS $$
    SELECT organization_id FROM profiles
    WHERE id = auth.uid()
    LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ------------------------------------------------------------------------------
-- 6. TABEL PROYEK & LAYANAN
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agency_services (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name                TEXT        NOT NULL,
    service_class       TEXT        DEFAULT 'digital_umum',
    service_category    TEXT        DEFAULT 'DIGITAL',
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS projects (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    client_id           UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title               TEXT        NOT NULL,
    service_type        TEXT,
    service_class       TEXT        DEFAULT 'digital_umum',
    project_category    TEXT        DEFAULT 'DIGITAL',
    status              TEXT        DEFAULT 'briefing',
    progress_percentage INTEGER     DEFAULT 0,
    deadline            DATE,
    total_price         NUMERIC     DEFAULT 0,
    payment_status      TEXT        DEFAULT 'pending',
    termin_1            NUMERIC     DEFAULT 0,
    termin_2            NUMERIC     DEFAULT 0,
    termin_3            NUMERIC     DEFAULT 0,
    preview_url         TEXT,
    link_youtube        TEXT,
    link_cloudinary     TEXT,
    skip_asset_cleanup  BOOLEAN     DEFAULT false,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS project_digital_details (
    project_id          UUID        PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE,
    assigned_staff_id   UUID        REFERENCES profiles(id) ON DELETE SET NULL,
    tech_stack          TEXT,
    git_repository      TEXT,
    design_figma_url    TEXT,
    production_url      TEXT,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS project_physical_details (
    project_id          UUID        PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE,
    spec_material       TEXT,
    spec_dimensions     TEXT,
    quantity            INTEGER     DEFAULT 1,
    unit                TEXT        DEFAULT 'pcs',
    finishing_notes     TEXT,
    assigned_designer_id UUID       REFERENCES profiles(id) ON DELETE SET NULL,
    assigned_operator_id UUID       REFERENCES profiles(id) ON DELETE SET NULL,
    assigned_packer_id   UUID       REFERENCES profiles(id) ON DELETE SET NULL,
    assigned_shipper_id  UUID       REFERENCES profiles(id) ON DELETE SET NULL,
    shipping_courier    TEXT,
    shipping_tracking_number TEXT,
    shipping_address    TEXT,
    design_approval_status TEXT     DEFAULT 'pending',
    production_status   TEXT        DEFAULT 'queued',
    packing_status      TEXT        DEFAULT 'unpacked',
    shipping_status     TEXT        DEFAULT 'not_shipped',
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS project_assets (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id          UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    category            TEXT        NOT NULL,
    file_name           TEXT        NOT NULL,
    file_url            TEXT        NOT NULL,
    file_size           BIGINT,
    mime_type           TEXT,
    uploaded_by         UUID        REFERENCES profiles(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS project_revisions (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id          UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    requested_by        UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    notes               TEXT        NOT NULL,
    status              TEXT        DEFAULT 'open',
    resolution_notes    TEXT,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    resolved_at         TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS internal_notes (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id          UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    author_id           UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content             TEXT        NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ------------------------------------------------------------------------------
-- 7. TABEL KEUANGAN & INVOICING
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fin_categories (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name                TEXT        NOT NULL,
    type                TEXT        NOT NULL CHECK (type IN ('INCOME', 'EXPENSE')),
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS fin_invoices (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    project_id          UUID        REFERENCES projects(id) ON DELETE SET NULL,
    client_id           UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    invoice_number      TEXT        NOT NULL,
    amount              NUMERIC     NOT NULL,
    due_date            DATE,
    status              TEXT        DEFAULT 'UNPAID',
    payment_channel     TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    paid_at             TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS fin_invoice_items (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    invoice_id          UUID        NOT NULL REFERENCES fin_invoices(id) ON DELETE CASCADE,
    description         TEXT        NOT NULL,
    quantity            INTEGER     DEFAULT 1,
    unit_price          NUMERIC     NOT NULL,
    total_price         NUMERIC     NOT NULL
);

CREATE TABLE IF NOT EXISTS fin_transactions (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    category_id         UUID        REFERENCES fin_categories(id) ON DELETE SET NULL,
    invoice_id          UUID        REFERENCES fin_invoices(id) ON DELETE SET NULL,
    type                TEXT        NOT NULL CHECK (type IN ('INCOME', 'EXPENSE')),
    amount              NUMERIC     NOT NULL,
    description         TEXT,
    transaction_date    DATE        DEFAULT CURRENT_DATE NOT NULL,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ------------------------------------------------------------------------------
-- 8. TABEL GUDANG & INVENTORI (MODUL FISIK)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_items (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name                TEXT        NOT NULL,
    category            TEXT        DEFAULT 'Umum',
    current_stock       NUMERIC     DEFAULT 0 NOT NULL,
    unit                TEXT        DEFAULT 'Pcs',
    min_stock_alert     NUMERIC     DEFAULT 5,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    item_id             UUID        NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    type                TEXT        NOT NULL CHECK (type IN ('IN', 'OUT', 'ADJUST')),
    quantity            NUMERIC     NOT NULL,
    notes               TEXT,
    actor_id            UUID        REFERENCES profiles(id) ON DELETE SET NULL,
    actor_name          TEXT,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS maintenance_tickets (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    machine_name        TEXT        NOT NULL,
    issue_description   TEXT        NOT NULL,
    priority            TEXT        DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    status              TEXT        DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved')),
    reported_by         UUID        REFERENCES profiles(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ------------------------------------------------------------------------------
-- 9. TABEL INTEGRASI GOOGLE SHEETS & AUDIT TRAIL
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agency_sheet_configs (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    agency_id           UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    sheet_role          TEXT        NOT NULL CHECK (sheet_role IN ('admin','staff')),
    sheet_id            TEXT        NOT NULL,
    tab_projects        TEXT        DEFAULT 'Projects',
    tab_finance         TEXT        DEFAULT 'Finance',
    tab_operations      TEXT        DEFAULT 'Operations',
    staff_edit_allowed  BOOLEAN     DEFAULT false,
    sync_mode           TEXT        DEFAULT 'manual' CHECK (sync_mode IN ('manual', 'realtime', 'scheduled')),
    sync_interval_hours INTEGER     DEFAULT 24,
    last_synced_at      TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at          TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE (agency_id, sheet_role)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id     UUID        REFERENCES organizations(id) ON DELETE CASCADE,
    actor_id            UUID,
    actor_email         TEXT,
    action              TEXT        NOT NULL,
    target_type         TEXT,
    target_id           TEXT,
    target_name         TEXT,
    metadata            JSONB,
    created_at          TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ------------------------------------------------------------------------------
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_digital_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_physical_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE internal_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE fin_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_sheet_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy Organizations
DROP POLICY IF EXISTS "Users can read own organization" ON organizations;
CREATE POLICY "Users can read own organization" ON organizations
    FOR SELECT USING (id = public.get_my_org_id());

-- Policy Profiles
DROP POLICY IF EXISTS "Users can read profiles in own organization" ON profiles;
CREATE POLICY "Users can read profiles in own organization" ON profiles
    FOR SELECT USING (organization_id = public.get_my_org_id() OR id = auth.uid());

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid());

-- Policy Projects
DROP POLICY IF EXISTS "Users can read projects in own organization" ON projects;
CREATE POLICY "Users can read projects in own organization" ON projects
    FOR SELECT USING (
        organization_id = public.get_my_org_id() 
        AND (
            public.has_permission(auth.uid(), 'projects.read') 
            OR client_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Staff with permission can manage projects" ON projects;
CREATE POLICY "Staff with permission can manage projects" ON projects
    FOR ALL USING (
        organization_id = public.get_my_org_id() 
        AND public.has_permission(auth.uid(), 'projects.manage')
    );

-- Policy Fin Invoices
DROP POLICY IF EXISTS "Users can read invoices in own organization" ON fin_invoices;
CREATE POLICY "Users can read invoices in own organization" ON fin_invoices
    FOR SELECT USING (
        organization_id = public.get_my_org_id() 
        AND (
            public.has_permission(auth.uid(), 'finance.read') 
            OR client_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Staff with permission can manage invoices" ON fin_invoices;
CREATE POLICY "Staff with permission can manage invoices" ON fin_invoices
    FOR ALL USING (
        organization_id = public.get_my_org_id() 
        AND public.has_permission(auth.uid(), 'finance.manage')
    );

-- Policy Inventory
DROP POLICY IF EXISTS "Staff can read inventory in own organization" ON inventory_items;
CREATE POLICY "Staff can read inventory in own organization" ON inventory_items
    FOR SELECT USING (
        organization_id = public.get_my_org_id() 
        AND public.has_permission(auth.uid(), 'warehouse.read')
    );

DROP POLICY IF EXISTS "Staff can manage inventory in own organization" ON inventory_items;
CREATE POLICY "Staff can manage inventory in own organization" ON inventory_items
    FOR ALL USING (
        organization_id = public.get_my_org_id() 
        AND public.has_permission(auth.uid(), 'warehouse.manage')
    );

-- Policy Google Sheets
DROP POLICY IF EXISTS "Admin can manage agency sheet configs" ON agency_sheet_configs;
CREATE POLICY "Admin can manage agency sheet configs" ON agency_sheet_configs
    FOR ALL USING (
        agency_id = public.get_my_org_id() 
        AND public.has_permission(auth.uid(), 'sheets.configure')
    );

-- Policy Maintenance Tickets
DROP POLICY IF EXISTS "Users can read maintenance tickets" ON maintenance_tickets;
CREATE POLICY "Users can read maintenance tickets" ON maintenance_tickets
    FOR SELECT USING (organization_id = public.get_my_org_id());

DROP POLICY IF EXISTS "Users can insert maintenance tickets" ON maintenance_tickets;
CREATE POLICY "Users can insert maintenance tickets" ON maintenance_tickets
    FOR INSERT WITH CHECK (organization_id = public.get_my_org_id());

-- Policy Audit Logs
DROP POLICY IF EXISTS "Admin can read audit logs" ON audit_logs;
CREATE POLICY "Admin can read audit logs" ON audit_logs
    FOR SELECT USING (organization_id = public.get_my_org_id());

-- ==============================================================================
-- SELESAI. Database Operasional CRM (db-crm) siap digunakan!
-- ==============================================================================
