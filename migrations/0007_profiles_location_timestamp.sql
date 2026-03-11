ALTER TABLE profiles
    ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ;

