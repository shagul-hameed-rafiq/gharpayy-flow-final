
-- 1. Create Lead
curl -X POST "$SUPABASE_URL/rest/v1/leads" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Postman Test", "phone": "1234567890", "source": "website"}'

-- 2. Get Leads (Agent) - Expect filtered list
curl -X GET "$SUPABASE_URL/rest/v1/leads?select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $AGENT_TOKEN"

-- 3. Get Leads (Manager) - Expect full list
curl -X GET "$SUPABASE_URL/rest/v1/leads?select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $MANAGER_TOKEN"

-- 4. Create Visit
curl -X POST "$SUPABASE_URL/rest/v1/visits" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $AGENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"lead_id": "$LEAD_ID", "property_id": "$PROP_ID", "scheduled_at": "2026-03-30T10:00:00Z"}'

-- 5. Send Conversation message
curl -X POST "$SUPABASE_URL/rest/v1/conversations" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $AGENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"lead_id": "$LEAD_ID", "message": "Verification test message", "direction": "outbound"}'

-- 6. Dashboard Stats (Admin/Manager)
curl -X GET "$SUPABASE_URL/rest/v1/leads?select=count&status=eq.new" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
