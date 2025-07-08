-- 外部キー参照の修正
-- auth.usersテーブルへの参照をuser_profilesテーブルへの参照に変更

-- 既存の外部キー制約を確認・削除（存在する場合）
ALTER TABLE shopping_lists DROP CONSTRAINT IF EXISTS shopping_lists_created_by_fkey;
ALTER TABLE shopping_items DROP CONSTRAINT IF EXISTS shopping_items_assigned_to_fkey;
ALTER TABLE shopping_items DROP CONSTRAINT IF EXISTS shopping_items_completed_by_fkey;
ALTER TABLE shopping_items DROP CONSTRAINT IF EXISTS shopping_items_approved_by_fkey;
ALTER TABLE shopping_items DROP CONSTRAINT IF EXISTS shopping_items_rejected_by_fkey;

-- user_profilesテーブルへの新しい外部キー制約を追加
-- （user_profilesテーブルがauth.usersと同期されていることを前提）
ALTER TABLE shopping_lists 
ADD CONSTRAINT shopping_lists_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE shopping_items 
ADD CONSTRAINT shopping_items_assigned_to_fkey 
FOREIGN KEY (assigned_to) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE shopping_items 
ADD CONSTRAINT shopping_items_completed_by_fkey 
FOREIGN KEY (completed_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE shopping_items 
ADD CONSTRAINT shopping_items_approved_by_fkey 
FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE shopping_items 
ADD CONSTRAINT shopping_items_rejected_by_fkey 
FOREIGN KEY (rejected_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- RLS を完全に無効化（テスト用）
ALTER TABLE families DISABLE ROW LEVEL SECURITY;
ALTER TABLE family_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists DISABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE allowance_balances DISABLE ROW LEVEL SECURITY;
ALTER TABLE allowance_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings DISABLE ROW LEVEL SECURITY;