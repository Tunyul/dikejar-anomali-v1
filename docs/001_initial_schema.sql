CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE wallets (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    coins BIGINT NOT NULL DEFAULT 0,
    gems BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE products (
    id VARCHAR(50) PRIMARY KEY,
    channel VARCHAR(50) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'idr',
    price_amount INTEGER NOT NULL,
    grants_json JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE topup_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    product_id VARCHAR(50) NOT NULL REFERENCES products(id),
    channel VARCHAR(50) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_txn_id VARCHAR(255),
    external_order_id VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL,
    amount INTEGER NOT NULL,
    raw_payload_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE grant_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL UNIQUE REFERENCES topup_transactions(id),
    grant_key VARCHAR(255) UNIQUE NOT NULL,
    coins_delta BIGINT NOT NULL DEFAULT 0,
    gems_delta BIGINT NOT NULL DEFAULT 0,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_type VARCHAR(50) NOT NULL,
    actor_id VARCHAR(255) NOT NULL,
    action VARCHAR(255) NOT NULL,
    object_type VARCHAR(50) NOT NULL,
    object_id VARCHAR(255) NOT NULL,
    payload_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);