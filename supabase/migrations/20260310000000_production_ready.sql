-- 1. Create Role Enum and Table
CREATE TYPE app_role AS ENUM ('admin', 'manager', 'agent', 'owner');

CREATE TABLE user_roles (
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  UNIQUE(user_id, role)
);

-- Enable RLS on user_roles
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own roles" ON user_roles FOR SELECT USING (auth.uid() = user_id);
-- Assuming admins can manage roles, or it's done via service role
CREATE POLICY "Admins manage roles" ON user_roles FOR ALL USING (
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
);

-- 2. Security Improvements & RBAC Policies
-- Drop permissive policies
DROP POLICY IF EXISTS "Auth users read agents" ON public.agents;
DROP POLICY IF EXISTS "Auth users manage agents" ON public.agents;
DROP POLICY IF EXISTS "Auth users update agents" ON public.agents;
DROP POLICY IF EXISTS "Auth users delete agents" ON public.agents;

DROP POLICY IF EXISTS "Auth users read properties" ON public.properties;
DROP POLICY IF EXISTS "Auth users manage properties" ON public.properties;
DROP POLICY IF EXISTS "Auth users update properties" ON public.properties;
DROP POLICY IF EXISTS "Auth users delete properties" ON public.properties;

DROP POLICY IF EXISTS "Auth users read leads" ON public.leads;
DROP POLICY IF EXISTS "Auth users manage leads" ON public.leads;
DROP POLICY IF EXISTS "Auth users update leads" ON public.leads;
DROP POLICY IF EXISTS "Auth users delete leads" ON public.leads;

DROP POLICY IF EXISTS "Auth users read visits" ON public.visits;
DROP POLICY IF EXISTS "Auth users manage visits" ON public.visits;
DROP POLICY IF EXISTS "Auth users update visits" ON public.visits;
DROP POLICY IF EXISTS "Auth users delete visits" ON public.visits;

-- New Stricter RLS Policies

-- AGENTS
-- Admins/Managers can manage agents. Agents can read all.
CREATE POLICY "Admins/Managers manage agents" ON public.agents FOR ALL USING (
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);
CREATE POLICY "Anyone can read active agents" ON public.agents FOR SELECT USING (is_active = true);

-- PROPERTIES
-- Owners can read their own. Admins/Managers can manage. Public can read active ones.
CREATE POLICY "Public read active properties" ON public.properties FOR SELECT USING (is_active = true);
CREATE POLICY "Admins/Managers manage properties" ON public.properties FOR ALL USING (
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);
CREATE POLICY "Owners read own properties" ON public.properties FOR SELECT USING (
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'owner') AND
  owner_id IN (SELECT id FROM public.owners WHERE user_id = auth.uid())
);

-- LEADS
-- Agents see their assigned leads. Managers/Admins see all. Anyone can insert (public form).
CREATE POLICY "Public insert leads" ON public.leads FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins/Managers manage all leads" ON public.leads FOR ALL USING (
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);
CREATE POLICY "Agents manage assigned leads" ON public.leads FOR ALL USING (
  assigned_agent_id IN (SELECT id FROM public.agents WHERE user_id = auth.uid())
);

-- VISITS
CREATE POLICY "Public insert visits" ON public.visits FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins/Managers manage all visits" ON public.visits FOR ALL USING (
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);
CREATE POLICY "Agents view assigned visits" ON public.visits FOR SELECT USING (
  assigned_staff_id IN (SELECT id FROM public.agents WHERE user_id = auth.uid()) OR
  lead_id IN (SELECT id FROM public.leads WHERE assigned_agent_id IN (SELECT id FROM public.agents WHERE user_id = auth.uid()))
);
CREATE POLICY "Agents update assigned visits" ON public.visits FOR UPDATE USING (
  assigned_staff_id IN (SELECT id FROM public.agents WHERE user_id = auth.uid()) OR
  lead_id IN (SELECT id FROM public.leads WHERE assigned_agent_id IN (SELECT id FROM public.agents WHERE user_id = auth.uid()))
);

-- CONVERSATIONS
DROP POLICY IF EXISTS "Auth users read conversations" ON public.conversations;
DROP POLICY IF EXISTS "Auth users manage conversations" ON public.conversations;

CREATE POLICY "Public insert conversations" ON public.conversations FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins/Managers manage conversations" ON public.conversations FOR ALL USING (
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);
CREATE POLICY "Agents view their conversations" ON public.conversations FOR SELECT USING (
  lead_id IN (SELECT id FROM public.leads WHERE assigned_agent_id IN (SELECT id FROM public.agents WHERE user_id = auth.uid()))
);

-- 3. Automation Jobs (Setup via pg_cron extension)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Job 1: Clean up expired soft locks every 15 minutes
SELECT cron.schedule('cleanup-expired-locks', '*/15 * * * *', $$
  DELETE FROM public.soft_locks WHERE expires_at < now();
$$);

-- Job 2: Auto-lock stale rooms daily
SELECT cron.schedule('auto-lock-stale-rooms', '0 1 * * *', $$
  SELECT public.auto_lock_stale_rooms();
$$);
