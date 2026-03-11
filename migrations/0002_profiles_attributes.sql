ALTER TABLE profiles
    ADD COLUMN IF NOT EXISTS target_gender_preference VARCHAR(32),
    ADD COLUMN IF NOT EXISTS attributes JSONB DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_profiles_attributes_gin
    ON profiles
    USING GIN (attributes);

