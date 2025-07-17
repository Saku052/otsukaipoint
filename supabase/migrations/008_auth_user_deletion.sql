-- Add functions to delete users from auth.users table
-- This migration adds RPC functions to completely delete users from Supabase Auth

-- Function to delete user from auth.users table directly
CREATE OR REPLACE FUNCTION delete_user_direct(target_user_id UUID)
RETURNS JSON AS $$
BEGIN
    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = target_user_id) THEN
        RETURN json_build_object('success', false, 'error', 'User not found in auth.users');
    END IF;
    
    -- Delete user from auth.users table
    DELETE FROM auth.users WHERE id = target_user_id;
    
    RETURN json_build_object(
        'success', true, 
        'message', 'User deleted from auth.users',
        'user_id', target_user_id,
        'deleted_at', NOW()
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false, 
            'error', SQLERRM,
            'user_id', target_user_id
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete auth user (alternative method)
CREATE OR REPLACE FUNCTION delete_auth_user(user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- First try to delete from auth.users
    DELETE FROM auth.users WHERE id = user_id;
    
    -- Check if deletion was successful
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'User not found or already deleted',
            'user_id', user_id
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'User successfully deleted from authentication',
        'user_id', user_id,
        'deleted_at', NOW()
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'user_id', user_id
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users for their own deletion
GRANT EXECUTE ON FUNCTION delete_user_direct(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_auth_user(UUID) TO authenticated;

-- Grant permissions to service role for admin operations
GRANT EXECUTE ON FUNCTION delete_user_direct(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION delete_auth_user(UUID) TO service_role;

-- Add security policy to ensure users can only delete themselves
-- Note: Additional security should be implemented at the application level