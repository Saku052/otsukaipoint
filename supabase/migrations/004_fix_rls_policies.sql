-- RLSポリシーの修正
-- 無限再帰を解決するために、family_membersテーブルのポリシーを修正

-- 既存のポリシーを削除
DROP POLICY IF EXISTS "Users can view family members" ON family_members;
DROP POLICY IF EXISTS "Family members can view shopping lists" ON shopping_lists;
DROP POLICY IF EXISTS "Parents can create shopping lists" ON shopping_lists;
DROP POLICY IF EXISTS "Parents can update shopping lists" ON shopping_lists;

-- 一時的にRLSを無効化（テスト用）
ALTER TABLE family_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists DISABLE ROW LEVEL SECURITY;

-- より単純なポリシーを作成
CREATE POLICY "Enable all access for authenticated users" ON family_members
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Enable all access for authenticated users" ON shopping_lists
    FOR ALL USING (auth.uid() IS NOT NULL);

-- RLSを再度有効化
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;