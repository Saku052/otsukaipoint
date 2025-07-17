-- Migration: Account Deletion Support
-- Description: Add immediate hard delete functionality for complete account deletion

-- 1. Add audit columns to user_profiles table (for logging purposes before deletion)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE NULL,
ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMP WITH TIME ZONE NULL;

-- 2. Add audit columns to families table for tracking
ALTER TABLE families 
ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMP WITH TIME ZONE NULL;

-- 3. Create account_deletion_logs table for audit trail
CREATE TABLE IF NOT EXISTS account_deletion_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- Store user ID even after user is deleted
    user_email TEXT NOT NULL, -- Store email for reference
    user_role VARCHAR(20) NOT NULL,
    family_id UUID, -- Store family ID for reference
    deletion_reason TEXT,
    deletion_type VARCHAR(20) NOT NULL CHECK (deletion_type IN ('immediate_hard', 'failed')),
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    ip_address INET,
    user_agent TEXT,
    additional_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create function to handle immediate hard delete of user account
CREATE OR REPLACE FUNCTION hard_delete_user_account(
    target_user_id UUID,
    cascade_delete BOOLEAN DEFAULT TRUE
) RETURNS JSON AS $$
DECLARE
    user_record RECORD;
    family_record RECORD;
    child_count INTEGER;
    result JSON;
BEGIN
    -- Get user information for logging
    SELECT up.*, au.email 
    INTO user_record 
    FROM user_profiles up
    LEFT JOIN auth.users au ON au.id = up.id
    WHERE up.id = target_user_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Handle family-related logic
    IF user_record.family_id IS NOT NULL THEN
        SELECT * INTO family_record FROM families WHERE id = user_record.family_id;
        
        -- If user is a parent, check for remaining children
        IF user_record.role = 'parent' THEN
            SELECT COUNT(*) INTO child_count 
            FROM user_profiles 
            WHERE family_id = user_record.family_id 
            AND role = 'child' 
            AND id != target_user_id;
            
            -- Set children to orphaned state (remove from family)
            IF child_count > 0 THEN
                UPDATE user_profiles 
                SET family_id = NULL, updated_at = NOW()
                WHERE family_id = user_record.family_id 
                AND role = 'child' 
                AND id != target_user_id;
            END IF;
        END IF;
    END IF;
    
    -- Log the deletion BEFORE actually deleting
    INSERT INTO account_deletion_logs (
        user_id, 
        user_email, 
        user_role, 
        family_id, 
        deletion_reason, 
        deletion_type,
        completed_at,
        additional_data
    ) VALUES (
        target_user_id,
        COALESCE(user_record.email, 'unknown'),
        user_record.role,
        user_record.family_id,
        'Immediate hard delete',
        'immediate_hard',
        NOW(),
        json_build_object(
            'cascade_delete', cascade_delete,
            'children_affected', child_count
        )
    );
    
    -- Delete related data in correct order
    IF cascade_delete THEN
        -- Delete shopping items
        DELETE FROM shopping_items WHERE user_id = target_user_id;
        
        -- Delete shopping lists
        DELETE FROM shopping_lists WHERE user_id = target_user_id;
        
        -- Delete family member relationships
        DELETE FROM family_members WHERE user_id = target_user_id;
        
        -- Delete notification settings
        DELETE FROM notification_settings WHERE user_id = target_user_id;
        
        -- Delete file upload records
        DELETE FROM file_uploads WHERE user_id = target_user_id;
        
        -- Delete user sessions
        DELETE FROM user_sessions WHERE user_id = target_user_id;
    END IF;
    
    -- Delete from auth.users (this will cascade to user_profiles due to FK constraint)
    DELETE FROM auth.users WHERE id = target_user_id;
    
    result := json_build_object(
        'success', true,
        'user_id', target_user_id,
        'hard_deleted_at', NOW(),
        'children_affected', child_count
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create function to get deletion statistics
CREATE OR REPLACE FUNCTION get_deletion_statistics(
    from_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    to_date TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    WITH stats AS (
        SELECT 
            deletion_reason,
            COUNT(*) as count,
            ROUND(
                (COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()),
                2
            ) as percentage
        FROM account_deletion_logs
        WHERE deletion_type = 'immediate_hard'
        AND (from_date IS NULL OR created_at >= from_date)
        AND (to_date IS NULL OR created_at <= to_date)
        GROUP BY deletion_reason
        ORDER BY count DESC
    )
    SELECT json_agg(
        json_build_object(
            'reason', COALESCE(deletion_reason, 'その他'),
            'count', count,
            'percentage', percentage
        )
    ) INTO result
    FROM stats;
    
    RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create table to track external service deletion failures
CREATE TABLE IF NOT EXISTS external_service_deletion_failures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    service_name VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    retry_count INTEGER DEFAULT 0,
    resolved_at TIMESTAMP WITH TIME ZONE NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_external_service_deletion_failures_user_id 
ON external_service_deletion_failures(user_id);

-- 7. Create view for user deletion audit
CREATE OR REPLACE VIEW user_deletion_audit AS
SELECT 
    adl.id,
    adl.user_id,
    adl.user_email,
    adl.user_role,
    adl.family_id,
    adl.deletion_reason,
    adl.deletion_type,
    adl.initiated_at,
    adl.completed_at,
    adl.ip_address,
    adl.additional_data,
    CASE 
        WHEN adl.deletion_type = 'immediate_hard' THEN 'Immediately Deleted'
        WHEN adl.deletion_type = 'failed' THEN 'Failed'
        ELSE 'Unknown'
    END as status_description
FROM account_deletion_logs adl
ORDER BY adl.created_at DESC;

-- 8. Security policies for account deletion functions
-- Ensure only authenticated users can delete their own accounts
ALTER FUNCTION hard_delete_user_account(UUID, BOOLEAN) SECURITY DEFINER;
ALTER FUNCTION get_deletion_statistics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION hard_delete_user_account(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION get_deletion_statistics(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO service_role;

-- 9. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_deletion_requested ON user_profiles(deletion_requested_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_login ON user_profiles(last_login_at);
CREATE INDEX IF NOT EXISTS idx_account_deletion_logs_user_id ON account_deletion_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_logs_deletion_type ON account_deletion_logs(deletion_type);
CREATE INDEX IF NOT EXISTS idx_account_deletion_logs_created_at ON account_deletion_logs(created_at);

-- 10. Add comments for documentation
COMMENT ON COLUMN user_profiles.deletion_requested_at IS 'Timestamp when account deletion was requested (for auditing).';
COMMENT ON COLUMN user_profiles.last_login_at IS 'Timestamp of the last login for inactive account cleanup.';

COMMENT ON TABLE account_deletion_logs IS 'Audit log for all account deletion activities including immediate hard delete and failed attempts.';
COMMENT ON TABLE external_service_deletion_failures IS 'Log of failures when deleting data from external services (files, images, etc.).';

COMMENT ON FUNCTION hard_delete_user_account IS 'Immediately and permanently delete a user account and all associated data. This operation is irreversible.';
COMMENT ON FUNCTION get_deletion_statistics IS 'Get statistics on account deletion reasons and frequencies.';

COMMENT ON VIEW user_deletion_audit IS 'Comprehensive view of all user deletion activities for administrative review.';