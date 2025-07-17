-- ユーザー情報拡張
-- 
-- このマイグレーションは以下を行います：
-- 1. usersテーブルの拡張（auth.usersとは別のプロファイルテーブル）
-- 2. 便利な関数とビューの作成

-- ユーザープロファイルテーブル（auth.usersの拡張）
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    email VARCHAR(255),
    avatar_url TEXT,
    role VARCHAR(20) DEFAULT 'child' CHECK (role IN ('parent', 'child')),
    family_id UUID REFERENCES families(id) ON DELETE SET NULL,
    date_of_birth DATE,
    phone VARCHAR(20),
    preferences JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_family_id ON user_profiles(family_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_active ON user_profiles(is_active);

-- RLS設定
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLSポリシー
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Family members can view each other" ON user_profiles
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM family_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- 自動更新トリガー
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 便利なビュー: 家族メンバーと詳細情報
CREATE OR REPLACE VIEW family_members_detailed AS
SELECT 
    fm.id,
    fm.family_id,
    fm.user_id,
    fm.role,
    fm.is_active,
    fm.joined_at,
    up.name,
    up.email,
    up.avatar_url,
    f.name as family_name
FROM family_members fm
JOIN user_profiles up ON fm.user_id = up.id
JOIN families f ON fm.family_id = f.id
WHERE fm.is_active = true AND f.is_active = true;

-- 便利なビュー: お小遣い統計
CREATE OR REPLACE VIEW allowance_stats AS
SELECT 
    ab.user_id,
    up.name as user_name,
    ab.balance,
    ab.total_earned,
    ab.total_spent,
    COALESCE(monthly.monthly_earned, 0) as monthly_earned,
    COALESCE(monthly.monthly_spent, 0) as monthly_spent,
    COALESCE(monthly.transaction_count, 0) as monthly_transactions
FROM allowance_balances ab
JOIN user_profiles up ON ab.user_id = up.id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(CASE WHEN type IN ('earned', 'bonus') THEN amount ELSE 0 END) as monthly_earned,
        SUM(CASE WHEN type IN ('spent', 'penalty') THEN amount ELSE 0 END) as monthly_spent,
        COUNT(*) as transaction_count
    FROM allowance_transactions 
    WHERE transaction_date >= date_trunc('month', CURRENT_DATE)
    GROUP BY user_id
) monthly ON ab.user_id = monthly.user_id;

-- 便利な関数: 家族の統計情報取得
CREATE OR REPLACE FUNCTION get_family_stats(family_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_members', COUNT(*),
        'parents', COUNT(*) FILTER (WHERE role = 'parent'),
        'children', COUNT(*) FILTER (WHERE role = 'child'),
        'active_lists', (
            SELECT COUNT(*) FROM shopping_lists 
            WHERE family_id = family_uuid AND is_active = true
        ),
        'pending_items', (
            SELECT COUNT(*) FROM shopping_items si
            JOIN shopping_lists sl ON si.shopping_list_id = sl.id
            WHERE sl.family_id = family_uuid AND si.status = 'pending'
        ),
        'total_allowance', (
            SELECT COALESCE(SUM(ab.balance), 0) FROM allowance_balances ab
            JOIN family_members fm ON ab.user_id = fm.user_id
            WHERE fm.family_id = family_uuid AND fm.is_active = true
        )
    ) INTO result
    FROM family_members 
    WHERE family_id = family_uuid AND is_active = true;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 便利な関数: ユーザーのお小遣い統計取得
CREATE OR REPLACE FUNCTION get_user_allowance_stats(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'current_balance', COALESCE(ab.balance, 0),
        'total_earned', COALESCE(ab.total_earned, 0),
        'total_spent', COALESCE(ab.total_spent, 0),
        'monthly_earned', COALESCE(monthly.earned, 0),
        'monthly_spent', COALESCE(monthly.spent, 0),
        'weekly_earned', COALESCE(weekly.earned, 0),
        'transaction_count', COALESCE(monthly.count, 0)
    ) INTO result
    FROM allowance_balances ab
    LEFT JOIN (
        SELECT 
            user_id,
            SUM(CASE WHEN type IN ('earned', 'bonus') THEN amount ELSE 0 END) as earned,
            SUM(CASE WHEN type IN ('spent', 'penalty') THEN amount ELSE 0 END) as spent,
            COUNT(*) as count
        FROM allowance_transactions 
        WHERE user_id = user_uuid 
        AND transaction_date >= date_trunc('month', CURRENT_DATE)
        GROUP BY user_id
    ) monthly ON ab.user_id = monthly.user_id
    LEFT JOIN (
        SELECT 
            user_id,
            SUM(CASE WHEN type IN ('earned', 'bonus') THEN amount ELSE 0 END) as earned
        FROM allowance_transactions 
        WHERE user_id = user_uuid 
        AND transaction_date >= date_trunc('week', CURRENT_DATE)
        GROUP BY user_id
    ) weekly ON ab.user_id = weekly.user_id
    WHERE ab.user_id = user_uuid;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- サンプルデータ挿入用関数（開発用）
CREATE OR REPLACE FUNCTION insert_sample_data()
RETURNS VOID AS $$
BEGIN
    -- この関数は開発環境でのみ使用
    -- 本番環境では実行しないでください
    RAISE NOTICE 'Sample data insertion function created. Use with caution.';
END;
$$ LANGUAGE plpgsql;