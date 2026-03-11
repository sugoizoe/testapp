ALTER TABLE users
    ADD COLUMN IF NOT EXISTS premium_expires_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS trial_used BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS video_call_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_call_reset_date TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS subscriptions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider        VARCHAR(32) NOT NULL,  -- 'apple' veya 'google'
    receipt_id      TEXT NOT NULL,
    raw_receipt     JSONB NOT NULL,
    currency        VARCHAR(8) NOT NULL,
    amount_cents    INT NOT NULL,
    status          VARCHAR(32) NOT NULL,  -- 'active', 'expired', 'canceled'
    purchased_at    TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_provider_receipt ON subscriptions(provider, receipt_id);

CREATE TABLE IF NOT EXISTS messages (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id     UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sender_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_type VARCHAR(32) NOT NULL,
    content      JSONB NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT messages_type_enum CHECK (message_type IN (
        'DATE_REQUEST',
        'LOCATION_SHARE',
        'TIME_PROPOSAL',
        'STATUS_UPDATE'
    ))
);

CREATE INDEX IF NOT EXISTS idx_messages_match_id_created_at ON messages(match_id, created_at);

