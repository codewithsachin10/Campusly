-- Temporarily allow full access to admin tables for the UI testing
CREATE POLICY "Allow all on roles" ON public.roles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on permissions" ON public.permissions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on role_permissions" ON public.role_permissions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on admin_profiles" ON public.admin_profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on admin_scopes" ON public.admin_scopes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on admin_audit_logs" ON public.admin_audit_logs FOR ALL USING (true) WITH CHECK (true);
