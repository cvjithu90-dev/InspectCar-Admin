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
DROP POLICY IF EXISTS "answers_select" ON public.inspection_answers;
CREATE POLICY "answers_select" ON public.inspection_answers FOR SELECT USING (true);
DROP POLICY IF EXISTS "answers_insert" ON public.inspection_answers;
CREATE POLICY "answers_insert" ON public.inspection_answers FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "answers_update" ON public.inspection_answers;
CREATE POLICY "answers_update" ON public.inspection_answers FOR UPDATE USING (true);
DROP POLICY IF EXISTS "answers_delete" ON public.inspection_answers;
CREATE POLICY "answers_delete" ON public.inspection_answers FOR DELETE USING (true);

ALTER TABLE public.inspection_photos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "photos_select" ON public.inspection_photos;
CREATE POLICY "photos_select" ON public.inspection_photos FOR SELECT USING (true);
DROP POLICY IF EXISTS "photos_insert" ON public.inspection_photos;
CREATE POLICY "photos_insert" ON public.inspection_photos FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "photos_update" ON public.inspection_photos;
CREATE POLICY "photos_update" ON public.inspection_photos FOR UPDATE USING (true);
DROP POLICY IF EXISTS "photos_delete" ON public.inspection_photos;
CREATE POLICY "photos_delete" ON public.inspection_photos FOR DELETE USING (true);

ALTER TABLE public.report_drafts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "drafts_select" ON public.report_drafts;
CREATE POLICY "drafts_select" ON public.report_drafts FOR SELECT USING (true);
DROP POLICY IF EXISTS "drafts_insert" ON public.report_drafts;
CREATE POLICY "drafts_insert" ON public.report_drafts FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "drafts_update" ON public.report_drafts;
CREATE POLICY "drafts_update" ON public.report_drafts FOR UPDATE USING (true);
DROP POLICY IF EXISTS "drafts_delete" ON public.report_drafts;
CREATE POLICY "drafts_delete" ON public.report_drafts FOR DELETE USING (true);

ALTER TABLE public.report_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "docs_select" ON public.report_documents;
CREATE POLICY "docs_select" ON public.report_documents FOR SELECT USING (true);
DROP POLICY IF EXISTS "docs_insert" ON public.report_documents;
CREATE POLICY "docs_insert" ON public.report_documents FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "docs_update" ON public.report_documents;
CREATE POLICY "docs_update" ON public.report_documents FOR UPDATE USING (true);
DROP POLICY IF EXISTS "docs_delete" ON public.report_documents;
CREATE POLICY "docs_delete" ON public.report_documents FOR DELETE USING (true);

ALTER TABLE public.report_repair_estimates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "estimates_select" ON public.report_repair_estimates;
CREATE POLICY "estimates_select" ON public.report_repair_estimates FOR SELECT USING (true);
DROP POLICY IF EXISTS "estimates_insert" ON public.report_repair_estimates;
CREATE POLICY "estimates_insert" ON public.report_repair_estimates FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "estimates_update" ON public.report_repair_estimates;
CREATE POLICY "estimates_update" ON public.report_repair_estimates FOR UPDATE USING (true);
DROP POLICY IF EXISTS "estimates_delete" ON public.report_repair_estimates;
CREATE POLICY "estimates_delete" ON public.report_repair_estimates FOR DELETE USING (true);

ALTER TABLE public.report_service_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "service_select" ON public.report_service_history;
CREATE POLICY "service_select" ON public.report_service_history FOR SELECT USING (true);
DROP POLICY IF EXISTS "service_insert" ON public.report_service_history;
CREATE POLICY "service_insert" ON public.report_service_history FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "service_update" ON public.report_service_history;
CREATE POLICY "service_update" ON public.report_service_history FOR UPDATE USING (true);
DROP POLICY IF EXISTS "service_delete" ON public.report_service_history;
CREATE POLICY "service_delete" ON public.report_service_history FOR DELETE USING (true);

ALTER TABLE public.report_audit_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "audit_select" ON public.report_audit_log;
CREATE POLICY "audit_select" ON public.report_audit_log FOR SELECT USING (true);
DROP POLICY IF EXISTS "audit_insert" ON public.report_audit_log;
CREATE POLICY "audit_insert" ON public.report_audit_log FOR INSERT WITH CHECK (true);

ALTER TABLE public.report_versions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "versions_select" ON public.report_versions;
CREATE POLICY "versions_select" ON public.report_versions FOR SELECT USING (true);
DROP POLICY IF EXISTS "versions_insert" ON public.report_versions;
CREATE POLICY "versions_insert" ON public.report_versions FOR INSERT WITH CHECK (true);

ALTER TABLE public.generated_pdfs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pdfs_select" ON public.generated_pdfs;
CREATE POLICY "pdfs_select" ON public.generated_pdfs FOR SELECT USING (true);
DROP POLICY IF EXISTS "pdfs_insert" ON public.generated_pdfs;
CREATE POLICY "pdfs_insert" ON public.generated_pdfs FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "pdfs_update" ON public.generated_pdfs;
CREATE POLICY "pdfs_update" ON public.generated_pdfs FOR UPDATE USING (true);

-- ============================================================
-- STORAGE BUCKET: report-documents (for admin-uploaded files)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('report-documents', 'report-documents', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "report_docs_upload" ON storage.objects;
CREATE POLICY "report_docs_upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'report-documents');

DROP POLICY IF EXISTS "report_docs_read" ON storage.objects;
CREATE POLICY "report_docs_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'report-documents');

DROP POLICY IF EXISTS "report_docs_delete" ON storage.objects;
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
