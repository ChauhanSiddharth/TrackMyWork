-- TrackMyWork Database Schema
-- PostgreSQL 15+
-- Complete schema with all tables, indexes, and constraints

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Indexes for users table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- ============================================================================
-- REFRESH TOKENS TABLE
-- ============================================================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for refresh_tokens table
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);

-- ============================================================================
-- TASKS TABLE
-- ============================================================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(50) NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT check_completed_status CHECK (
        (status = 'completed' AND completed_at IS NOT NULL) OR
        (status != 'completed' AND completed_at IS NULL)
    )
);

-- Indexes for tasks table
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);
CREATE INDEX idx_tasks_tags ON tasks USING GIN(tags);
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_user_due_date ON tasks(user_id, due_date);

-- Full-text search index for tasks
CREATE INDEX idx_tasks_title_search ON tasks USING GIN(to_tsvector('english', title));
CREATE INDEX idx_tasks_description_search ON tasks USING GIN(to_tsvector('english', COALESCE(description, '')));

-- ============================================================================
-- IDEAS TABLE
-- ============================================================================
CREATE TABLE ideas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    tags TEXT[] DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'new'
        CHECK (status IN ('new', 'under_consideration', 'planned', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for ideas table
CREATE INDEX idx_ideas_user_id ON ideas(user_id);
CREATE INDEX idx_ideas_category ON ideas(category);
CREATE INDEX idx_ideas_tags ON ideas USING GIN(tags);
CREATE INDEX idx_ideas_status ON ideas(status);
CREATE INDEX idx_ideas_created_at ON ideas(created_at DESC);
CREATE INDEX idx_ideas_user_category ON ideas(user_id, category);

-- Full-text search index for ideas
CREATE INDEX idx_ideas_title_search ON ideas USING GIN(to_tsvector('english', title));
CREATE INDEX idx_ideas_description_search ON ideas USING GIN(to_tsvector('english', COALESCE(description, '')));

-- ============================================================================
-- FINANCE TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE finance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL
        CHECK (transaction_type IN ('income', 'expense', 'savings', 'investment')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(10) DEFAULT 'USD' NOT NULL,
    category VARCHAR(100),
    description TEXT,
    transaction_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for finance_transactions table
CREATE INDEX idx_finance_user_id ON finance_transactions(user_id);
CREATE INDEX idx_finance_type ON finance_transactions(transaction_type);
CREATE INDEX idx_finance_category ON finance_transactions(category);
CREATE INDEX idx_finance_date ON finance_transactions(transaction_date DESC);
CREATE INDEX idx_finance_created_at ON finance_transactions(created_at DESC);
CREATE INDEX idx_finance_user_type ON finance_transactions(user_id, transaction_type);
CREATE INDEX idx_finance_user_date ON finance_transactions(user_id, transaction_date);
CREATE INDEX idx_finance_user_category ON finance_transactions(user_id, category);

-- Full-text search index for finance
CREATE INDEX idx_finance_description_search ON finance_transactions
    USING GIN(to_tsvector('english', COALESCE(description, '')));

-- ============================================================================
-- SECURE NOTES TABLE
-- ============================================================================
CREATE TABLE secure_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    encrypted_content TEXT NOT NULL,
    encryption_key_id VARCHAR(100) DEFAULT 'master_key_v1',
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for secure_notes table
CREATE INDEX idx_secure_notes_user_id ON secure_notes(user_id);
CREATE INDEX idx_secure_notes_tags ON secure_notes USING GIN(tags);
CREATE INDEX idx_secure_notes_created_at ON secure_notes(created_at DESC);

-- Title search only (content is encrypted)
CREATE INDEX idx_secure_notes_title_search ON secure_notes
    USING GIN(to_tsvector('english', title));

-- ============================================================================
-- REMINDERS TABLE
-- ============================================================================
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    reminder_time TIMESTAMP NOT NULL,
    is_sent BOOLEAN DEFAULT FALSE,
    related_entity_type VARCHAR(50) CHECK (related_entity_type IN ('task', 'idea', 'finance', 'note', NULL)),
    related_entity_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraint to ensure reminder_time is in the future when created
    CONSTRAINT check_future_reminder CHECK (reminder_time > created_at)
);

-- Indexes for reminders table
CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_reminders_time ON reminders(reminder_time);
CREATE INDEX idx_reminders_sent ON reminders(is_sent);
CREATE INDEX idx_reminders_entity ON reminders(related_entity_type, related_entity_id);
CREATE INDEX idx_reminders_user_time ON reminders(user_id, reminder_time);
CREATE INDEX idx_reminders_pending ON reminders(reminder_time, is_sent) WHERE is_sent = FALSE;

-- ============================================================================
-- DASHBOARD CONFIGURATION TABLE (Optional - for user preferences)
-- ============================================================================
CREATE TABLE dashboard_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    enabled_dashlets TEXT[] DEFAULT '{recent_tasks,recent_expenses,recent_ideas,upcoming_reminders}',
    dashlet_order INTEGER[] DEFAULT '{0,1,2,3}',
    items_per_dashlet INTEGER DEFAULT 5 CHECK (items_per_dashlet BETWEEN 1 AND 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dashboard_configs_user_id ON dashboard_configs(user_id);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to all tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ideas_updated_at BEFORE UPDATE ON ideas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_finance_updated_at BEFORE UPDATE ON finance_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON secure_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON reminders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dashboard_configs_updated_at BEFORE UPDATE ON dashboard_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Optional but Recommended
-- ============================================================================

-- Enable RLS on user-owned tables
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE secure_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_configs ENABLE ROW LEVEL SECURITY;

-- Note: RLS policies would be defined in application layer or via PostgreSQL roles
-- Example policy (commented out - implement based on your auth strategy):
/*
CREATE POLICY tasks_user_policy ON tasks
    FOR ALL
    TO authenticated_user
    USING (user_id = current_setting('app.user_id')::UUID);
*/

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

-- View: User statistics
CREATE OR REPLACE VIEW user_statistics AS
SELECT
    u.id as user_id,
    u.username,
    u.email,
    COUNT(DISTINCT t.id) as total_tasks,
    COUNT(DISTINCT CASE WHEN t.status = 'completed' THEN t.id END) as completed_tasks,
    COUNT(DISTINCT i.id) as total_ideas,
    COUNT(DISTINCT f.id) as total_transactions,
    COUNT(DISTINCT n.id) as total_notes,
    COUNT(DISTINCT r.id) as total_reminders
FROM users u
LEFT JOIN tasks t ON u.id = t.user_id
LEFT JOIN ideas i ON u.id = i.user_id
LEFT JOIN finance_transactions f ON u.id = f.user_id
LEFT JOIN secure_notes n ON u.id = n.user_id
LEFT JOIN reminders r ON u.id = r.user_id
GROUP BY u.id, u.username, u.email;

-- View: Monthly finance summary per user
CREATE OR REPLACE VIEW monthly_finance_summary AS
SELECT
    user_id,
    DATE_TRUNC('month', transaction_date) as month,
    transaction_type,
    SUM(amount) as total_amount,
    COUNT(*) as transaction_count,
    AVG(amount) as average_amount
FROM finance_transactions
GROUP BY user_id, DATE_TRUNC('month', transaction_date), transaction_type;

-- ============================================================================
-- SAMPLE DATA (for development)
-- ============================================================================

-- Create admin user (password: 'admin123' - hashed with bcrypt)
-- Note: Replace with actual bcrypt hash
INSERT INTO users (email, username, password_hash, role) VALUES
('admin@trackmywork.com', 'admin', '$2b$12$example_hash_here', 'admin');

-- Create regular user (password: 'user123')
-- Note: Replace with actual bcrypt hash
INSERT INTO users (email, username, password_hash, role) VALUES
('user@example.com', 'johndoe', '$2b$12$example_hash_here', 'user');

-- ============================================================================
-- PERFORMANCE OPTIMIZATION QUERIES
-- ============================================================================

-- Analyze tables for query planner
ANALYZE users;
ANALYZE tasks;
ANALYZE ideas;
ANALYZE finance_transactions;
ANALYZE secure_notes;
ANALYZE reminders;

-- Create statistics for better query planning
CREATE STATISTICS tasks_user_status_stats ON user_id, status FROM tasks;
CREATE STATISTICS finance_user_type_stats ON user_id, transaction_type FROM finance_transactions;

-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

-- Clean up old revoked refresh tokens (run periodically)
-- DELETE FROM refresh_tokens WHERE is_revoked = TRUE AND created_at < NOW() - INTERVAL '30 days';

-- Clean up sent reminders older than 90 days
-- DELETE FROM reminders WHERE is_sent = TRUE AND reminder_time < NOW() - INTERVAL '90 days';

-- ============================================================================
-- BACKUP & RESTORE COMMANDS
-- ============================================================================

-- Backup database:
-- pg_dump -U username -d trackmywork -F c -f trackmywork_backup.dump

-- Restore database:
-- pg_restore -U username -d trackmywork -v trackmywork_backup.dump

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
