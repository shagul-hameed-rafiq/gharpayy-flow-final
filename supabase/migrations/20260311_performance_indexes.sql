
-- Performance Optimization: Production Indexes
-- These indexes accelerate RLS checks and common CRM queries at scale (30+ users, 10k+ daily visitors)

-- 1. Accelerate Auth-to-Entity mapping (used in nearly all RLS policies)
CREATE INDEX IF NOT EXISTS idx_agents_user_id ON public.agents(user_id);
CREATE INDEX IF NOT EXISTS idx_owners_user_id ON public.owners(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- 2. Optimize CRM Lead Management & Pipeline
CREATE INDEX IF NOT EXISTS idx_leads_assigned_agent ON public.leads(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_leads_status ON public.leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_property_id ON public.leads(property_id);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON public.leads(created_at DESC);

-- 3. Optimize Visit Scheduling & Outcomes
CREATE INDEX IF NOT EXISTS idx_visits_lead_id ON public.visits(lead_id);
CREATE INDEX IF NOT EXISTS idx_visits_property_id ON public.visits(property_id);
CREATE INDEX IF NOT EXISTS idx_visits_scheduled_at ON public.visits(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_visits_assigned_staff ON public.visits(assigned_staff_id);

-- 4. Optimize Conversations & Notifications
CREATE INDEX IF NOT EXISTS idx_conversations_lead_id ON public.conversations(lead_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id, created_at DESC);

-- 5. Optimize Owner Portal & Property Data
CREATE INDEX IF NOT EXISTS idx_properties_owner_id ON public.properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_bookings_property_id ON public.bookings(property_id);
CREATE INDEX IF NOT EXISTS idx_rooms_property_id ON public.rooms(property_id);
CREATE INDEX IF NOT EXISTS idx_beds_room_id ON public.beds(room_id);

-- 6. Soft Lock Cleanup performance
CREATE INDEX IF NOT EXISTS idx_soft_locks_active_expiry ON public.soft_locks(is_active, expires_at);
