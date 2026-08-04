-- ============================================================
-- InspectCar — Extended Schema for Report Generator Wizard
-- Run this AFTER supabase-setup.sql in the Supabase SQL Editor
-- ============================================================

-- ============================================================
-- TABLE 1: inspection_answers
-- Written by the Inspector PWA when submitting a checklist
-- ============================================================
CREATE TABLE IF NOT EXISTS public.inspection_answers (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id       UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  inspector_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  category         TEXT NOT NULL,
  item_name        TEXT NOT NULL,
  answer           TEXT NOT NULL DEFAULT 'na',
  severity         TEXT DEFAULT 'low',
  remarks          TEXT,
  paint_thickness  NUMERIC,
  obd_value        TEXT,
  gps_location     TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inspection_answers_booking ON public.inspection_answers(booking_id);
CREATE INDEX IF NOT EXISTS idx_inspection_answers_category ON public.inspection_answers(booking_id, category);

ALTER TABLE public.inspection_answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "answers_select"  ON public.inspection_answers FOR SELECT TO authenticated USING (true);
CREATE POLICY "answers_insert"  ON public.inspection_answers FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "answers_insert_anon" ON public.inspection_answers FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "answers_update"  ON public.inspection_answers FOR UPDATE TO authenticated USING (true);
CREATE POLICY "answers_delete"  ON public.inspection_answers FOR DELETE TO authenticated USING (true);

-- ============================================================
-- TABLE 2: inspection_photos
-- Photos attached to checklist items by the Inspector PWA
-- ============================================================
CREATE TABLE IF NOT EXISTS public.inspection_photos (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  category     TEXT,
  item_name    TEXT,
  caption      TEXT,
  photo_url    TEXT NOT NULL,
  sort_order   INTEGER DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inspection_photos_booking ON public.inspection_photos(booking_id);

ALTER TABLE public.inspection_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "photos_select"       ON public.inspection_photos FOR SELECT USING (true);
CREATE POLICY "photos_insert_auth"  ON public.inspection_photos FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "photos_insert_anon"  ON public.inspection_photos FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "photos_update"       ON public.inspection_photos FOR UPDATE TO authenticated USING (true);
CREATE POLICY "photos_delete"       ON public.inspection_photos FOR DELETE TO authenticated USING (true);

-- ============================================================
-- TABLE 3: report_drafts
-- Admin wizard state — saved as a JSON blob per booking.
-- Auto-saved every 30 seconds and on every step change.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.report_drafts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID UNIQUE NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  draft_data   JSONB NOT NULL DEFAULT '{}',
  current_step INTEGER DEFAULT 1,
  last_saved   TIMESTAMPTZ DEFAULT NOW(),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.report_drafts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "drafts_select" ON public.report_drafts FOR SELECT TO authenticated USING (true);
CREATE POLICY "drafts_insert" ON public.report_drafts FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "drafts_update" ON public.report_drafts FOR UPDATE TO authenticated USING (true);
CREATE POLICY "drafts_delete" ON public.report_drafts FOR DELETE TO authenticated USING (true);

-- ============================================================
-- TABLE 4: report_documents
-- Supporting files uploaded by admin: RC, Insurance, Service History PDFs, etc.
-- Actual files stored in Supabase Storage bucket 'report-documents'
-- ============================================================
CREATE TABLE IF NOT EXISTS public.report_documents (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  doc_type     TEXT NOT NULL, -- 'rc_copy' | 'insurance' | 'service_history' | 'invoice' | 'warranty' | 'puc' | 'other'
  file_name    TEXT NOT NULL,
  file_url     TEXT NOT NULL,
  file_size    INTEGER,
  mime_type    TEXT,
  description  TEXT,
  uploaded_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_docs_booking ON public.report_documents(booking_id);

ALTER TABLE public.report_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "docs_select" ON public.report_documents FOR SELECT TO authenticated USING (true);
CREATE POLICY "docs_insert" ON public.report_documents FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "docs_update" ON public.report_documents FOR UPDATE TO authenticated USING (true);
CREATE POLICY "docs_delete" ON public.report_documents FOR DELETE TO authenticated USING (true);

-- ============================================================
-- TABLE 5: report_repair_estimates
-- Itemized repair cost entries added by admin in wizard Step 7
-- ============================================================
CREATE TABLE IF NOT EXISTS public.report_repair_estimates (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  category     TEXT NOT NULL,
  component    TEXT NOT NULL,
  description  TEXT,
  severity     TEXT DEFAULT 'medium', -- 'low' | 'medium' | 'high' | 'critical'
  est_cost_min INTEGER DEFAULT 0,
  est_cost_max INTEGER DEFAULT 0,
  priority     INTEGER DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_repair_estimates_booking ON public.report_repair_estimates(booking_id);

ALTER TABLE public.report_repair_estimates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "estimates_select" ON public.report_repair_estimates FOR SELECT TO authenticated USING (true);
CREATE POLICY "estimates_insert" ON public.report_repair_estimates FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "estimates_update" ON public.report_repair_estimates FOR UPDATE TO authenticated USING (true);
CREATE POLICY "estimates_delete" ON public.report_repair_estimates FOR DELETE TO authenticated USING (true);

-- ============================================================
-- TABLE 6: report_service_history
-- Vehicle service records entered or uploaded by admin in Step 5
-- ============================================================
CREATE TABLE IF NOT EXISTS public.report_service_history (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id      UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  service_date    DATE,
  dealer_name     TEXT,
  service_center  TEXT,
  odometer_km     INTEGER,
  service_type    TEXT, -- 'dealer' | 'authorized' | 'local' | 'oem'
  description     TEXT,
  cost            INTEGER,
  doc_url         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_history_booking ON public.report_service_history(booking_id);

ALTER TABLE public.report_service_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "service_select" ON public.report_service_history FOR SELECT TO authenticated USING (true);
CREATE POLICY "service_insert" ON public.report_service_history FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "service_update" ON public.report_service_history FOR UPDATE TO authenticated USING (true);
CREATE POLICY "service_delete" ON public.report_service_history FOR DELETE TO authenticated USING (true);

-- ============================================================
-- TABLE 7: report_audit_log
-- Every field change the admin makes is logged here
-- ============================================================
CREATE TABLE IF NOT EXISTS public.report_audit_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  admin_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_email  TEXT,
  action       TEXT NOT NULL, -- 'field_edit' | 'file_upload' | 'api_fetch' | 'publish' | 'draft_save'
  field_path   TEXT,
  old_value    TEXT,
  new_value    TEXT,
  ip_address   TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_booking ON public.report_audit_log(booking_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_time    ON public.report_audit_log(created_at DESC);

ALTER TABLE public.report_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_select" ON public.report_audit_log FOR SELECT TO authenticated USING (true);
CREATE POLICY "audit_insert" ON public.report_audit_log FOR INSERT TO authenticated WITH CHECK (true);

-- ============================================================
-- TABLE 8: report_versions
-- Every time admin publishes, a new version snapshot is saved
-- ============================================================
CREATE TABLE IF NOT EXISTS public.report_versions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id     UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL DEFAULT 1,
  report_data    JSONB NOT NULL,
  published_by   TEXT,
  notes          TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_versions_booking ON public.report_versions(booking_id);

ALTER TABLE public.report_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "versions_select" ON public.report_versions FOR SELECT TO authenticated USING (true);
CREATE POLICY "versions_insert" ON public.report_versions FOR INSERT TO authenticated WITH CHECK (true);

-- ============================================================
-- TABLE 9: generated_pdfs
-- Metadata for every PDF generated (URL, version, timestamp)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.generated_pdfs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id     UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  version_id     UUID REFERENCES public.report_versions(id),
  share_token    TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT,
  file_url       TEXT,
  generated_at   TIMESTAMPTZ DEFAULT NOW(),
  generated_by   TEXT,
  download_count INTEGER DEFAULT 0,
  is_public      BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_pdfs_booking ON public.generated_pdfs(booking_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pdfs_token ON public.generated_pdfs(share_token);

ALTER TABLE public.generated_pdfs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pdfs_select" ON public.generated_pdfs FOR SELECT USING (true);
CREATE POLICY "pdfs_insert" ON public.generated_pdfs FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "pdfs_update" ON public.generated_pdfs FOR UPDATE TO authenticated USING (true);

-- ============================================================
-- STORAGE BUCKET: report-documents (for admin-uploaded files)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('report-documents', 'report-documents', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "report_docs_upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'report-documents');

CREATE POLICY "report_docs_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'report-documents');

CREATE POLICY "report_docs_delete" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'report-documents');

-- ============================================================
-- HELPER: Add vahan_data and admin_notes columns to bookings
-- (stores raw VAHAN API response and admin notes on the booking)
-- ============================================================
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS vahan_data       JSONB,
  ADD COLUMN IF NOT EXISTS admin_notes      TEXT,
  ADD COLUMN IF NOT EXISTS vin_number       TEXT,
  ADD COLUMN IF NOT EXISTS odometer_km      INTEGER,
  ADD COLUMN IF NOT EXISTS owner_count      INTEGER,
  ADD COLUMN IF NOT EXISTS insurance_expiry DATE,
  ADD COLUMN IF NOT EXISTS puc_expiry       DATE,
  ADD COLUMN IF NOT EXISTS fitness_expiry   DATE,
  ADD COLUMN IF NOT EXISTS tax_expiry       DATE,
  ADD COLUMN IF NOT EXISTS reg_date         DATE,
  ADD COLUMN IF NOT EXISTS rto_code         TEXT,
  ADD COLUMN IF NOT EXISTS chassis_number   TEXT,
  ADD COLUMN IF NOT EXISTS engine_number    TEXT,
  ADD COLUMN IF NOT EXISTS color            TEXT,
  ADD COLUMN IF NOT EXISTS body_type        TEXT;

-- ============================================================
-- HELPER: Add report_status and ai_score to bookings
-- (tracks where the booking is in the report workflow)
-- ============================================================
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS report_status  TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS ai_score       NUMERIC,
  ADD COLUMN IF NOT EXISTS verdict        TEXT;

-- report_status values:
--   'pending'               — booking created, not yet inspected
--   'inspection_completed'  — inspector submitted checklist
--   'report_draft'          — admin started wizard, saved draft
--   'report_published'      — admin published the final report
--   'report_sent'           — PDF sent to customer

-- ============================================================
-- SUCCESS
-- ============================================================
-- All 9 tables created.
-- Run this SQL in: Supabase Dashboard → SQL Editor → New Query → Run
-- ============================================================
