do $$
begin
    if exists (
        select 1
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname = 'get_group_invite_preview'
          and pg_get_function_identity_arguments(p.oid) = 'p_token text'
          and pg_get_function_result(p.oid) <> 'jsonb'
    ) then
        execute 'drop function public.get_group_invite_preview(text)';
    end if;
end $$;
