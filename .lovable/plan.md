

# Plan: Bookings Table + Full Booking Flow + Smart Innovations

## What We're Building

Two major additions without touching existing working code:

### Part 1: Bookings Table & Full Flow

**Database Migration:**
- New `bookings` table: `id`, `lead_id`, `property_id`, `room_id`, `bed_id`, `visit_id` (optional), `booking_status` enum (`pending`, `confirmed`, `cancelled`, `checked_in`, `checked_out`), `monthly_rent`, `security_deposit`, `move_in_date`, `move_out_date`, `payment_status` enum (`unpaid`, `partial`, `paid`), `notes`, `booked_by` (agent), `created_at`, `updated_at`
- New `booking_status` and `payment_status` enums
- RLS policies (authenticated CRUD)
- Trigger: `on_visit_booked` — when visits.outcome set to 'booked', auto-create a soft lock (hard_lock, 24h) on the bed + insert a pending booking row
- Trigger: `on_booking_confirmed` — when booking_status changes to 'confirmed', update the bed status to 'booked'
- Trigger: `on_booking_cancelled` — release soft lock and revert bed to 'vacant'
- Enable realtime on bookings table

**Frontend — New `/bookings` page:**
- Table view of all bookings with status badges, lead name, property, room, bed, rent, move-in date
- Inline status change (pending → confirmed → checked_in)
- Cancel booking action with confirmation
- Filter by status, property
- KPI row: Total bookings, Pending, Confirmed, Revenue (sum of monthly_rent for confirmed)

**Hook: `useBookings.ts`**
- `useBookings()`, `useCreateBooking()`, `useUpdateBooking()`
- Wire into existing visit outcome flow — when agent selects "Booked" on Visits page, the trigger handles the rest automatically

**Sidebar update:** Add "Bookings" under Demand section with a Receipt icon

### Part 2: Innovations (Additive Only)

**1. AI Lead Summary (Smart Box Enhancement)**
- Add an "AI Summarize" button in the `LeadDetailDrawer` that calls a Lovable AI edge function
- Sends lead data + conversations + visits to `google/gemini-2.5-flash`
- Returns a 3-line summary: lead intent, urgency level, recommended next action
- Displayed as a card at the top of the drawer

**2. AI Follow-up Message Generator**
- In `ConversationChat`, add a "Suggest Reply" button
- Calls edge function with last 5 messages + lead context
- Returns 2-3 suggested WhatsApp reply templates the agent can copy with one click

**3. Revenue Forecasting Widget**
- New card on Dashboard showing projected monthly revenue
- Calculates from: confirmed bookings rent + (pending bookings rent × 0.6 probability) + (visit_scheduled leads × avg rent × 0.25)
- Simple bar chart: This month vs Next month projected

**4. Smart Notifications for Booking Events**
- Auto-insert notifications when: booking created, booking confirmed, booking cancelled, bed status changed
- Uses existing `notifications` table — just add insert triggers

**5. Booking Timeline on Lead Detail**
- In `LeadDetailDrawer`, add a visual timeline: Lead Created → Contacted → Visit → Booking → Confirmed
- Shows actual dates from activity_log + visits + bookings

## Files to Create/Modify

**New files:**
- `supabase/migrations/[timestamp]_create_bookings.sql` — schema + triggers
- `src/hooks/useBookings.ts` — data hooks
- `src/pages/Bookings.tsx` — bookings management page
- `supabase/functions/ai-lead-summary/index.ts` — AI summary edge function
- `supabase/functions/ai-suggest-reply/index.ts` — AI reply suggestions

**Modified files:**
- `src/App.tsx` — add /bookings route
- `src/components/AppSidebar.tsx` — add Bookings nav item
- `src/pages/Dashboard.tsx` — add revenue forecast widget
- `src/components/LeadDetailDrawer.tsx` — add AI summary + booking timeline
- `src/components/ConversationChat.tsx` — add suggest reply button
- `src/pages/Visits.tsx` — outcome "booked" now triggers the full flow automatically (no code change needed, DB trigger handles it)

## Technical Notes

- All DB triggers use `SECURITY DEFINER` to bypass RLS for cross-table operations
- Edge functions use `LOVABLE_API_KEY` (already configured) for AI model access
- No existing code is modified in breaking ways — only additive changes
- Bookings table has foreign keys to leads, properties, rooms, beds (all nullable except lead_id)

