-- RPC to get active sessions for the current authenticated user
CREATE OR REPLACE FUNCTION get_active_sessions()
RETURNS json AS $$
DECLARE
  sessions_data json;
BEGIN
  -- We select from auth.sessions using SECURITY DEFINER
  -- This allows the function to bypass RLS and schema restrictions
  SELECT json_agg(
    json_build_object(
      'id', id,
      'created_at', created_at,
      'updated_at', updated_at,
      'user_agent', user_agent,
      'ip', ip
    )
  ) INTO sessions_data
  FROM auth.sessions
  WHERE user_id = auth.uid();
  
  -- Return empty array instead of null if no sessions found
  RETURN coalesce(sessions_data, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- RPC to revoke a specific session for the current authenticated user
CREATE OR REPLACE FUNCTION revoke_session(session_id uuid)
RETURNS void AS $$
BEGIN
  -- Ensure the user is only deleting their own session
  DELETE FROM auth.sessions
  WHERE id = session_id AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
