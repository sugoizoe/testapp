CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           CITEXT UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    is_premium      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profiles (
    user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    full_name       VARCHAR(255) NOT NULL,
    birth_date      DATE NOT NULL,
    gender          VARCHAR(32) NOT NULL,
    bio             TEXT,
    location        GEOGRAPHY(POINT, 4326),
    city            VARCHAR(128),
    country         VARCHAR(128),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_location_geo
    ON profiles
    USING GIST (location);

CREATE TABLE IF NOT EXISTS swipes (
    id              BIGSERIAL PRIMARY KEY,
    swiper_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action          VARCHAR(16) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_swipe_per_pair UNIQUE (swiper_id, target_id)
);

CREATE INDEX IF NOT EXISTS idx_swipes_swiper_id_created_at
    ON swipes (swiper_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_swipes_target_id_created_at
    ON swipes (target_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matches (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_match_pair UNIQUE (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id)),
    CONSTRAINT match_not_self CHECK (user1_id <> user2_id)
);

CREATE INDEX IF NOT EXISTS idx_matches_user1_id_created_at
    ON matches (user1_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_matches_user2_id_created_at
    ON matches (user2_id, created_at DESC);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

