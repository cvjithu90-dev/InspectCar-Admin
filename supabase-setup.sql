-- ============================================================
-- InspectCar — Supabase Database Setup (Fixed Version)
-- Paste this in Supabase SQL Editor → Run and enable RLS
-- ============================================================

-- 1. PROFILES TABLE (Admins & Inspectors)
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   TEXT NOT NULL DEFAULT 'User',
  phone       TEXT,
  role        TEXT NOT NULL DEFAULT 'inspector',
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BOOKINGS TABLE
CREATE TABLE IF NOT EXISTS public.bookings (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  booking_ref      TEXT UNIQUE NOT NULL,
  customer_name    TEXT NOT NULL,
  customer_phone   TEXT NOT NULL,
  customer_email   TEXT,
  vehicle_brand    TEXT,
  vehicle_model    TEXT,
  vehicle_year     TEXT,
  vehicle_fuel     TEXT,
  vehicle_reg      TEXT,
  package_name     TEXT NOT NULL,
  base_price       INTEGER NOT NULL DEFAULT 0,
  discount         INTEGER DEFAULT 0,
  total_price      INTEGER NOT NULL DEFAULT 0,
  promo_code       TEXT,
  inspection_date  DATE NOT NULL,
  inspection_time  TEXT NOT NULL,
  location_type    TEXT,
  address          TEXT,
  area             TEXT,
  status           TEXT NOT NULL DEFAULT 'pending',
  payment_method   TEXT DEFAULT 'pay-at-site',
  payment_status   TEXT DEFAULT 'unpaid',
  inspector_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  source           TEXT DEFAULT 'website',
  notes            TEXT
);

-- 3. INSPECTION REPORTS TABLE
CREATE TABLE IF NOT EXISTS public.inspection_reports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id        UUID REFERENCES public.bookings(id) ON DELETE CASCADE NOT NULL,
  inspector_id      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ai_score          INTEGER,
  overall_condition TEXT,
  recommendation    TEXT,
  summary           TEXT,
  started_at        TIMESTAMPTZ DEFAULT NOW(),
  completed_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- 4. INSPECTION CHECKLIST ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.inspection_checklist_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id   UUID REFERENCES public.inspection_reports(id) ON DELETE CASCADE NOT NULL,
  booking_id  UUID REFERENCES public.bookings(id) ON DELETE CASCADE NOT NULL,
  category    TEXT NOT NULL,
  item_name   TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'na',
  note        TEXT,
  photo_url   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 5. RLS POLICIES FOR profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE TO authenticated USING (true);

-- 6. RLS POLICIES FOR bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bookings_select" ON public.bookings
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "bookings_insert_auth" ON public.bookings
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "bookings_insert_anon" ON public.bookings
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "bookings_update" ON public.bookings
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "bookings_delete" ON public.bookings
  FOR DELETE TO authenticated USING (true);

-- 7. RLS POLICIES FOR inspection_reports
ALTER TABLE public.inspection_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reports_select" ON public.inspection_reports
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "reports_insert" ON public.inspection_reports
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "reports_update" ON public.inspection_reports
  FOR UPDATE TO authenticated USING (true);

-- 8. RLS POLICIES FOR inspection_checklist_items
ALTER TABLE public.inspection_checklist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "checklist_select" ON public.inspection_checklist_items
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "checklist_insert" ON public.inspection_checklist_items
  FOR INSERT TO authenticated WITH CHECK (true);

-- 9. STORAGE BUCKET FOR INSPECTION PHOTOS
INSERT INTO storage.buckets (id, name, public)
VALUES ('inspection-photos', 'inspection-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "photos_upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'inspection-photos');

CREATE POLICY "photos_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'inspection-photos');

-- 10. SAMPLE TEST BOOKINGS
INSERT INTO public.bookings (
  booking_ref, customer_name, customer_phone,
  vehicle_brand, vehicle_model, vehicle_year, vehicle_fuel,
  package_name, base_price, total_price,
  inspection_date, inspection_time,
  location_type, area, status, source
) VALUES
(
  'IC-2026-1001', 'Rahul Sharma', '+91 98765 43210',
  'Maruti Suzuki', 'Swift ZXi', '2021', 'Petrol',
  'Lux-Drive', 3999, 3999,
  CURRENT_DATE + 1, '10:30 AM',
  'Seller Yard', 'HSR Layout', 'pending', 'website'
),
(
  'IC-2026-1002', 'Arjun Nair', '+91 87654 32109',
  'Hyundai', 'Creta SX', '2022', 'Diesel',
  'Lux-Drive', 3999, 3999,
  CURRENT_DATE, '9:00 AM',
  'Used Car Dealership', 'Koramangala', 'pending', 'website'
);

-- ============================================================
-- SUCCESS! All tables created.
-- Next: Go to Authentication > Users > Add user (your admin)
-- Then run: UPDATE public.profiles SET role='admin' WHERE id='YOUR-USER-ID';
-- ============================================================
