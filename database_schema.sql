-- おつかいポイント データベーススキーマ
-- Supabase PostgreSQL

-- UUIDs拡張を有効化
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ユーザーロール列挙型
CREATE TYPE user_role AS ENUM ('parent', 'child');

-- 商品ステータス列挙型
CREATE TYPE item_status AS ENUM ('pending', 'completed', 'approved', 'rejected');

-- 通知タイプ列挙型
CREATE TYPE notification_type AS ENUM ('item_added', 'item_completed', 'item_approved', 'item_rejected', 'list_created');

-- ユーザーテーブル
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'parent',
    name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- 子供の場合の追加情報
    last_name_change_at TIMESTAMP WITH TIME ZONE,
    
    -- 親の場合の追加情報
    family_id UUID,
    
    CONSTRAINT check_name_not_empty CHECK (LENGTH(TRIM(name)) > 0)
);

-- 家族グループテーブル
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    qr_code TEXT,
    qr_code_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT check_family_name_not_empty CHECK (LENGTH(TRIM(name)) > 0)
);

-- 家族メンバーテーブル（親子関係）
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(family_id, user_id)
);

-- 買い物リストテーブル
CREATE TABLE shopping_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    deadline TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT check_title_not_empty CHECK (LENGTH(TRIM(title)) > 0)
);

-- 買い物商品テーブル
CREATE TABLE shopping_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    estimated_price DECIMAL(10,2),
    suggested_store TEXT,
    allowance_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    status item_status DEFAULT 'pending',
    assigned_to UUID REFERENCES users(id),
    completed_by UUID REFERENCES users(id),
    completed_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT check_name_not_empty CHECK (LENGTH(TRIM(name)) > 0),
    CONSTRAINT check_allowance_positive CHECK (allowance_amount >= 0),
    CONSTRAINT check_estimated_price_positive CHECK (estimated_price IS NULL OR estimated_price >= 0)
);

-- お小遣い残高テーブル
CREATE TABLE allowance_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    balance DECIMAL(10,2) NOT NULL DEFAULT 0,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, family_id),
    CONSTRAINT check_balance_not_negative CHECK (balance >= 0)
);

-- お小遣い取引履歴テーブル
CREATE TABLE allowance_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    shopping_item_id UUID REFERENCES shopping_items(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_type TEXT NOT NULL, -- 'earned', 'spent', 'adjustment'
    description TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_amount_not_zero CHECK (amount != 0),
    CONSTRAINT check_transaction_type CHECK (transaction_type IN ('earned', 'spent', 'adjustment'))
);

-- 通知テーブル
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT check_title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
    CONSTRAINT check_message_not_empty CHECK (LENGTH(TRIM(message)) > 0)
);

-- 通知設定テーブル
CREATE TABLE notification_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_added BOOLEAN DEFAULT TRUE,
    item_completed BOOLEAN DEFAULT TRUE,
    item_approved BOOLEAN DEFAULT TRUE,
    item_rejected BOOLEAN DEFAULT TRUE,
    list_created BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- インデックス作成
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_family_id ON users(family_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_deleted_at ON users(deleted_at);

CREATE INDEX idx_families_deleted_at ON families(deleted_at);
CREATE INDEX idx_families_qr_code_expires_at ON families(qr_code_expires_at);

CREATE INDEX idx_family_members_family_id ON family_members(family_id);
CREATE INDEX idx_family_members_user_id ON family_members(user_id);
CREATE INDEX idx_family_members_role ON family_members(role);

CREATE INDEX idx_shopping_lists_family_id ON shopping_lists(family_id);
CREATE INDEX idx_shopping_lists_created_by ON shopping_lists(created_by);
CREATE INDEX idx_shopping_lists_deadline ON shopping_lists(deadline);
CREATE INDEX idx_shopping_lists_deleted_at ON shopping_lists(deleted_at);

CREATE INDEX idx_shopping_items_shopping_list_id ON shopping_items(shopping_list_id);
CREATE INDEX idx_shopping_items_status ON shopping_items(status);
CREATE INDEX idx_shopping_items_assigned_to ON shopping_items(assigned_to);
CREATE INDEX idx_shopping_items_completed_by ON shopping_items(completed_by);
CREATE INDEX idx_shopping_items_deleted_at ON shopping_items(deleted_at);

CREATE INDEX idx_allowance_balances_user_id ON allowance_balances(user_id);
CREATE INDEX idx_allowance_balances_family_id ON allowance_balances(family_id);

CREATE INDEX idx_allowance_transactions_user_id ON allowance_transactions(user_id);
CREATE INDEX idx_allowance_transactions_family_id ON allowance_transactions(family_id);
CREATE INDEX idx_allowance_transactions_shopping_item_id ON allowance_transactions(shopping_item_id);
CREATE INDEX idx_allowance_transactions_created_at ON allowance_transactions(created_at);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_family_id ON notifications(family_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- RLS (Row Level Security) 設定
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE allowance_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE allowance_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- RLS ポリシー作成
-- users テーブル
CREATE POLICY "Users can view their own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- families テーブル
CREATE POLICY "Family members can view their family" ON families FOR SELECT USING (
    id IN (SELECT family_id FROM family_members WHERE user_id = auth.uid() AND is_active = TRUE)
);

-- family_members テーブル
CREATE POLICY "Family members can view family members" ON family_members FOR SELECT USING (
    family_id IN (SELECT family_id FROM family_members WHERE user_id = auth.uid() AND is_active = TRUE)
);

-- shopping_lists テーブル
CREATE POLICY "Family members can view shopping lists" ON shopping_lists FOR SELECT USING (
    family_id IN (SELECT family_id FROM family_members WHERE user_id = auth.uid() AND is_active = TRUE)
);
CREATE POLICY "Parents can manage shopping lists" ON shopping_lists FOR ALL USING (
    family_id IN (
        SELECT fm.family_id FROM family_members fm 
        JOIN users u ON fm.user_id = u.id 
        WHERE u.id = auth.uid() AND u.role = 'parent' AND fm.is_active = TRUE
    )
);

-- shopping_items テーブル
CREATE POLICY "Family members can view shopping items" ON shopping_items FOR SELECT USING (
    shopping_list_id IN (
        SELECT sl.id FROM shopping_lists sl
        JOIN family_members fm ON sl.family_id = fm.family_id
        WHERE fm.user_id = auth.uid() AND fm.is_active = TRUE
    )
);
CREATE POLICY "Parents can manage shopping items" ON shopping_items FOR ALL USING (
    shopping_list_id IN (
        SELECT sl.id FROM shopping_lists sl
        JOIN family_members fm ON sl.family_id = fm.family_id
        JOIN users u ON fm.user_id = u.id
        WHERE u.id = auth.uid() AND u.role = 'parent' AND fm.is_active = TRUE
    )
);
CREATE POLICY "Children can update assigned items" ON shopping_items FOR UPDATE USING (
    assigned_to = auth.uid() OR completed_by = auth.uid()
);

-- allowance_balances テーブル
CREATE POLICY "Users can view their own balance" ON allowance_balances FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Parents can view family balances" ON allowance_balances FOR SELECT USING (
    family_id IN (
        SELECT fm.family_id FROM family_members fm 
        JOIN users u ON fm.user_id = u.id 
        WHERE u.id = auth.uid() AND u.role = 'parent' AND fm.is_active = TRUE
    )
);

-- allowance_transactions テーブル
CREATE POLICY "Users can view their own transactions" ON allowance_transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Parents can view family transactions" ON allowance_transactions FOR SELECT USING (
    family_id IN (
        SELECT fm.family_id FROM family_members fm 
        JOIN users u ON fm.user_id = u.id 
        WHERE u.id = auth.uid() AND u.role = 'parent' AND fm.is_active = TRUE
    )
);

-- notifications テーブル
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update their own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- notification_settings テーブル
CREATE POLICY "Users can manage their notification settings" ON notification_settings FOR ALL USING (user_id = auth.uid());

-- 更新日時自動更新のトリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 更新日時自動更新トリガー
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_families_updated_at BEFORE UPDATE ON families FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_family_members_updated_at BEFORE UPDATE ON family_members FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shopping_lists_updated_at BEFORE UPDATE ON shopping_lists FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shopping_items_updated_at BEFORE UPDATE ON shopping_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_allowance_balances_updated_at BEFORE UPDATE ON allowance_balances FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_settings_updated_at BEFORE UPDATE ON notification_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- お小遣い残高更新のトリガー関数
CREATE OR REPLACE FUNCTION update_allowance_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- 商品が承認された場合
    IF NEW.status = 'approved' AND OLD.status = 'completed' THEN
        -- 残高更新
        INSERT INTO allowance_balances (user_id, family_id, balance)
        VALUES (NEW.completed_by, (SELECT family_id FROM shopping_lists WHERE id = NEW.shopping_list_id), NEW.allowance_amount)
        ON CONFLICT (user_id, family_id) 
        DO UPDATE SET 
            balance = allowance_balances.balance + NEW.allowance_amount,
            last_updated_at = NOW();
        
        -- 取引履歴追加
        INSERT INTO allowance_transactions (user_id, family_id, shopping_item_id, amount, transaction_type, description)
        VALUES (
            NEW.completed_by, 
            (SELECT family_id FROM shopping_lists WHERE id = NEW.shopping_list_id),
            NEW.id,
            NEW.allowance_amount,
            'earned',
            'お使い完了: ' || NEW.name
        );
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- お小遣い残高更新トリガー
CREATE TRIGGER update_allowance_on_approval 
    AFTER UPDATE ON shopping_items 
    FOR EACH ROW 
    EXECUTE FUNCTION update_allowance_balance();

-- QRコード期限切れクリーンアップ関数
CREATE OR REPLACE FUNCTION cleanup_expired_qr_codes()
RETURNS void AS $$
BEGIN
    UPDATE families 
    SET qr_code = NULL, qr_code_expires_at = NULL
    WHERE qr_code_expires_at < NOW();
END;
$$ language 'plpgsql';

-- 初期データ挿入用関数
CREATE OR REPLACE FUNCTION initialize_user_data(user_id UUID, user_email TEXT)
RETURNS void AS $$
BEGIN
    -- 通知設定を作成
    INSERT INTO notification_settings (user_id)
    VALUES (user_id)
    ON CONFLICT (user_id) DO NOTHING;
END;
$$ language 'plpgsql';