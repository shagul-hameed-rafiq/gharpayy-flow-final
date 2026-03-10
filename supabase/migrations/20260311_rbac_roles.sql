
-- 1. Role enum
DO $$ BEGIN
    CREATE TYPE app_role AS ENUM ('admin', 'manager', 'agent', 'owner');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. user_roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, role)
);

-- Enable RLS
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 3. Default role assignment (Trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user_role()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role)
  VALUES (new.id, 'agent'); -- Default to agent for CRM users
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if trigger already exists to avoid error
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created_role') THEN
        CREATE TRIGGER on_auth_user_created_role
          AFTER INSERT ON auth.users
          FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_role();
    END IF;
END $$;

-- 4. RLS Policies for user_roles
DROP POLICY IF EXISTS "Users can read own roles" ON public.user_roles;
CREATE POLICY "Users can read own roles" ON public.user_roles FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins manage roles" ON public.user_roles;
CREATE POLICY "Admins manage roles" ON public.user_roles FOR ALL USING (
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin')
);

-- 5. Strict Role-Based Policies for LEADS
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Auth users read leads" ON public.leads;
DROP POLICY IF EXISTS "Auth users manage leads" ON public.leads;
DROP POLICY IF EXISTS "Auth users update leads" ON public.leads;
DROP POLICY IF EXISTS "Auth users delete leads" ON public.leads;
DROP POLICY IF EXISTS "Public insert leads" ON public.leads;
DROP POLICY IF EXISTS "Admins/Managers access all leads" ON public.leads;
DROP POLICY IF EXISTS "Agents manage assigned leads" ON public.leads;

CREATE POLICY "Public insert leads" ON public.leads FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins/Managers access all leads" ON public.leads FOR ALL USING (
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);

CREATE POLICY "Agents manage assigned leads" ON public.leads FOR ALL USING (
  assigned_agent_id IN (SELECT id FROM public.agents WHERE user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);

-- 6. Strict Role-Based Policies for PROPERTIES
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public select properties" ON public.properties;
DROP POLICY IF EXISTS "Admins/Managers manage properties" ON public.properties;
DROP POLICY IF EXISTS "Owners manage own properties" ON public.properties;

CREATE POLICY "Public select properties" ON public.properties FOR SELECT USING (is_active = true);

CREATE POLICY "Admins/Managers manage properties" ON public.properties FOR ALL USING (
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);

CREATE POLICY "Owners manage own properties" ON public.properties FOR ALL USING (
  owner_id IN (SELECT id FROM public.owners WHERE user_id = auth.uid())
);

-- 7. RE-CHECK CRM ACCESS FOR OTHER TABLES
-- VISITS
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Staff access visits" ON public.visits;
CREATE POLICY "Staff access visits" ON public.visits FOR ALL USING (
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager', 'agent'))
);

-- CONVERSATIONS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Staff access conversations" ON public.conversations;
CREATE POLICY "Staff access conversations" ON public.conversations FOR ALL USING (
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager', 'agent'))
);

-- BOOKINGS
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Staff manage bookings" ON public.bookings;
CREATE POLICY "Staff manage bookings" ON public.bookings FOR ALL USING (
  EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager', 'agent'))
);

DROP POLICY IF EXISTS "Owners view own bookings" ON public.bookings;
CREATE POLICY "Owners view own bookings" ON public.bookings FOR SELECT USING (
  property_id IN (
    SELECT id FROM public.properties WHERE owner_id IN (
      SELECT id FROM public.owners WHERE user_id = auth.uid()
    )
  )
);

-- ROOMS & BEDS (Owner access)
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Owners manage own rooms" ON public.rooms;
CREATE POLICY "Owners manage own rooms" ON public.rooms FOR ALL USING (
  property_id IN (
    SELECT id FROM public.properties WHERE owner_id IN (
      SELECT id FROM public.owners WHERE user_id = auth.uid()
    )
  ) OR EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);

ALTER TABLE public.beds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Owners manage own beds" ON public.beds;
CREATE POLICY "Owners manage own beds" ON public.beds FOR ALL USING (
  room_id IN (
    SELECT id FROM public.rooms WHERE property_id IN (
      SELECT id FROM public.properties WHERE owner_id IN (
        SELECT id FROM public.owners WHERE user_id = auth.uid()
      )
    )
  ) OR EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin', 'manager'))
);

-- OWNERS & AGENTS (Self-read)
ALTER TABLE public.owners ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Owners manage self" ON public.owners;
CREATE POLICY "Owners manage self" ON public.owners FOR ALL USING (user_id = auth.uid());

ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Agents manage self" ON public.agents;
CREATE POLICY "Agents manage self" ON public.agents FOR ALL USING (user_id = auth.uid());
