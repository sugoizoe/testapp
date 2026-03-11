CREATE TABLE IF NOT EXISTS statuses (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    location    GEOGRAPHY(POINT, 4326) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_statuses_location_geo
    ON statuses
    USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_statuses_expires_at
    ON statuses (expires_at);

CREATE TABLE IF NOT EXISTS status_requests (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status_id     UUID NOT NULL REFERENCES statuses(id) ON DELETE CASCADE,
    requester_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    state         VARCHAR(16) NOT NULL DEFAULT 'pending',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT status_requests_state_enum CHECK (state IN ('pending', 'accepted', 'rejected')),
    CONSTRAINT unique_request_per_user_per_status UNIQUE (status_id, requester_id)
);

CREATE INDEX IF NOT EXISTS idx_status_requests_status_id ON status_requests(status_id);

