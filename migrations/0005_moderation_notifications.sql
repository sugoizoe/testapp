CREATE TABLE IF NOT EXISTS user_blocks (
    blocker_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT user_blocks_unique_pair UNIQUE (blocker_id, blocked_id),
    CONSTRAINT user_blocks_not_self CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker_id ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked_id ON user_blocks(blocked_id);

CREATE TABLE IF NOT EXISTS user_reports (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason       VARCHAR(32) NOT NULL,
    description  TEXT,
    context_id   UUID,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT user_reports_reason_enum CHECK (reason IN ('NUDITY', 'HARASSMENT', 'SPAM', 'SCAM'))
);

CREATE INDEX IF NOT EXISTS idx_user_reports_reported_id ON user_reports(reported_id);

CREATE TABLE IF NOT EXISTS fcm_tokens (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       VARCHAR(512) NOT NULL UNIQUE,
    device_type VARCHAR(32) NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);

