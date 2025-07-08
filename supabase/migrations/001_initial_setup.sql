-- おつかいポイントアプリ初期セットアップ
-- 
-- このマイグレーションは以下のテーブルを作成します：
-- 1. families - 家族情報
-- 2. family_members - 家族メンバー
-- 3. allowance_balances - お小遣い残高
-- 4. allowance_transactions - お小遣い取引履歴

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 家族テーブル
CREATE TABLE IF NOT EXISTS families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    invite_code VARCHAR(10) UNIQUE,
    qr_code TEXT,
    qr_code_expires_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 家族メンバーテーブル  
CREATE TABLE IF NOT EXISTS family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('parent', 'child')),
    is_active BOOLEAN DEFAULT true,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- お小遣い残高テーブル
CREATE TABLE IF NOT EXISTS allowance_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    balance DECIMAL(10,2) DEFAULT 0.00 CHECK (balance >= 0),
    total_earned DECIMAL(10,2) DEFAULT 0.00 CHECK (total_earned >= 0),
    total_spent DECIMAL(10,2) DEFAULT 0.00 CHECK (total_spent >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- お小遣い取引履歴テーブル
CREATE TABLE IF NOT EXISTS allowance_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('earned', 'spent', 'adjustment', 'bonus', 'penalty')),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    related_item_id UUID, -- 外部キー制約は後で追加
    related_shopping_list_id UUID, -- 外部キー制約は後で追加
    approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    approved_by_name VARCHAR(255),
    shopping_list_title VARCHAR(255),
    balance_before DECIMAL(10,2) NOT NULL CHECK (balance_before >= 0),
    balance_after DECIMAL(10,2) NOT NULL CHECK (balance_after >= 0),
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);
CREATE INDEX IF NOT EXISTS idx_families_active ON families(is_active);
CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family_members(user_id);
CREATE INDEX IF NOT EXISTS idx_family_members_active ON family_members(is_active);
CREATE INDEX IF NOT EXISTS idx_allowance_balances_user_id ON allowance_balances(user_id);
CREATE INDEX IF NOT EXISTS idx_allowance_transactions_user_id ON allowance_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_allowance_transactions_type ON allowance_transactions(type);
CREATE INDEX IF NOT EXISTS idx_allowance_transactions_date ON allowance_transactions(transaction_date);

-- RLS (Row Level Security) 設定
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE allowance_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE allowance_transactions ENABLE ROW LEVEL SECURITY;

-- RLS ポリシー作成
-- 家族テーブル: メンバーのみアクセス可能
CREATE POLICY "Users can view their family" ON families
    FOR SELECT USING (
        id IN (
            SELECT family_id FROM family_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

CREATE POLICY "Parents can update their family" ON families
    FOR UPDATE USING (
        id IN (
            SELECT family_id FROM family_members 
            WHERE user_id = auth.uid() AND role = 'parent' AND is_active = true
        )
    );

-- 家族メンバーテーブル: 同じ家族のメンバーのみアクセス可能
CREATE POLICY "Users can view family members" ON family_members
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM family_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- お小遣い残高テーブル: 本人と家族の親のみアクセス可能
CREATE POLICY "Users can view their own allowance balance" ON allowance_balances
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Parents can view children allowance balances" ON allowance_balances
    FOR SELECT USING (
        user_id IN (
            SELECT fm_child.user_id 
            FROM family_members fm_child
            JOIN family_members fm_parent ON fm_child.family_id = fm_parent.family_id
            WHERE fm_parent.user_id = auth.uid() 
            AND fm_parent.role = 'parent' 
            AND fm_child.role = 'child'
            AND fm_child.is_active = true
            AND fm_parent.is_active = true
        )
    );

-- お小遣い取引履歴テーブル: 本人と家族の親のみアクセス可能
CREATE POLICY "Users can view their own allowance transactions" ON allowance_transactions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Parents can view children allowance transactions" ON allowance_transactions
    FOR SELECT USING (
        user_id IN (
            SELECT fm_child.user_id 
            FROM family_members fm_child
            JOIN family_members fm_parent ON fm_child.family_id = fm_parent.family_id
            WHERE fm_parent.user_id = auth.uid() 
            AND fm_parent.role = 'parent' 
            AND fm_child.role = 'child'
            AND fm_child.is_active = true
            AND fm_parent.is_active = true
        )
    );

-- 自動更新トリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_at自動更新トリガー
CREATE TRIGGER update_families_updated_at 
    BEFORE UPDATE ON families 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_family_members_updated_at 
    BEFORE UPDATE ON family_members 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_allowance_balances_updated_at 
    BEFORE UPDATE ON allowance_balances 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();