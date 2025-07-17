-- 買い物リスト関連テーブル
-- 
-- このマイグレーションは以下のテーブルを作成/更新します：
-- 1. shopping_lists - 買い物リスト
-- 2. shopping_items - 買い物アイテム
-- 3. notifications - 通知システム

-- 買い物リストテーブル
CREATE TABLE IF NOT EXISTS shopping_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 買い物アイテムテーブル
CREATE TABLE IF NOT EXISTS shopping_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shopping_list_id UUID REFERENCES shopping_lists(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
    unit VARCHAR(50),
    estimated_price DECIMAL(10,2),
    allowance_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (allowance_amount >= 0),
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    completed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'approved', 'rejected')),
    priority INTEGER DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
    category VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 通知テーブル
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'item_added', 'item_completed', 'item_approved', 'item_rejected', 'list_created',
        'shopping_completed', 'shopping_approved', 'shopping_rejected', 
        'family_invitation', 'allowance_received', 'system_update'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 通知設定テーブル
CREATE TABLE IF NOT EXISTS notification_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    item_added BOOLEAN DEFAULT true,
    item_completed BOOLEAN DEFAULT true,
    item_approved BOOLEAN DEFAULT true,
    item_rejected BOOLEAN DEFAULT true,
    list_created BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_shopping_lists_family_id ON shopping_lists(family_id);
CREATE INDEX IF NOT EXISTS idx_shopping_lists_created_by ON shopping_lists(created_by);
CREATE INDEX IF NOT EXISTS idx_shopping_lists_active ON shopping_lists(is_active);

CREATE INDEX IF NOT EXISTS idx_shopping_items_list_id ON shopping_items(shopping_list_id);
CREATE INDEX IF NOT EXISTS idx_shopping_items_assigned_to ON shopping_items(assigned_to);
CREATE INDEX IF NOT EXISTS idx_shopping_items_completed_by ON shopping_items(completed_by);
CREATE INDEX IF NOT EXISTS idx_shopping_items_status ON shopping_items(status);
CREATE INDEX IF NOT EXISTS idx_shopping_items_category ON shopping_items(category);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_family_id ON notifications(family_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- RLS設定
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- RLSポリシー: 買い物リスト
CREATE POLICY "Family members can view shopping lists" ON shopping_lists
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM family_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

CREATE POLICY "Parents can create shopping lists" ON shopping_lists
    FOR INSERT WITH CHECK (
        created_by = auth.uid() AND
        family_id IN (
            SELECT family_id FROM family_members 
            WHERE user_id = auth.uid() AND role = 'parent' AND is_active = true
        )
    );

CREATE POLICY "Parents can update shopping lists" ON shopping_lists
    FOR UPDATE USING (
        family_id IN (
            SELECT family_id FROM family_members 
            WHERE user_id = auth.uid() AND role = 'parent' AND is_active = true
        )
    );

-- RLSポリシー: 買い物アイテム
CREATE POLICY "Family members can view shopping items" ON shopping_items
    FOR SELECT USING (
        shopping_list_id IN (
            SELECT sl.id FROM shopping_lists sl
            JOIN family_members fm ON sl.family_id = fm.family_id
            WHERE fm.user_id = auth.uid() AND fm.is_active = true
        )
    );

CREATE POLICY "Parents can manage shopping items" ON shopping_items
    FOR ALL USING (
        shopping_list_id IN (
            SELECT sl.id FROM shopping_lists sl
            JOIN family_members fm ON sl.family_id = fm.family_id
            WHERE fm.user_id = auth.uid() AND fm.role = 'parent' AND fm.is_active = true
        )
    );

CREATE POLICY "Children can update assigned items" ON shopping_items
    FOR UPDATE USING (
        assigned_to = auth.uid() OR completed_by = auth.uid()
    );

-- RLSポリシー: 通知
CREATE POLICY "Users can view their notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- RLSポリシー: 通知設定
CREATE POLICY "Users can manage their notification settings" ON notification_settings
    FOR ALL USING (user_id = auth.uid());

-- 自動更新トリガー
CREATE TRIGGER update_shopping_lists_updated_at 
    BEFORE UPDATE ON shopping_lists 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_items_updated_at 
    BEFORE UPDATE ON shopping_items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_settings_updated_at 
    BEFORE UPDATE ON notification_settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- allowance_transactionsテーブルに外部キー制約を追加
-- （001_initial_setup.sqlで作成済みのテーブルに制約を追加）
ALTER TABLE allowance_transactions 
ADD CONSTRAINT fk_allowance_transactions_related_item_id 
FOREIGN KEY (related_item_id) REFERENCES shopping_items(id) ON DELETE SET NULL;

ALTER TABLE allowance_transactions 
ADD CONSTRAINT fk_allowance_transactions_related_shopping_list_id 
FOREIGN KEY (related_shopping_list_id) REFERENCES shopping_lists(id) ON DELETE SET NULL;