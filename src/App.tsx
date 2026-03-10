import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import AuthGuard from "@/components/AuthGuard";
import Dashboard from "./pages/Dashboard";
import Leads from "./pages/Leads";
import Pipeline from "./pages/Pipeline";
import Visits from "./pages/Visits";
import Conversations from "./pages/Conversations";
import Analytics from "./pages/Analytics";
import Historical from "./pages/Historical";
import SettingsPage from "./pages/SettingsPage";
import LeadCapture from "./pages/LeadCapture";
import Owners from "./pages/Owners";
import Inventory from "./pages/Inventory";
import EffortDashboard from "./pages/EffortDashboard";
import Availability from "./pages/Availability";
import Matching from "./pages/Matching";
import Bookings from "./pages/Bookings";
import ZoneManagement from "./pages/ZoneManagement";
import Explore from "./pages/Explore";
import PropertyDetail from "./pages/PropertyDetail";
import LandingPage from "./pages/LandingPage";
import Auth from "./pages/Auth";
import ResetPassword from "./pages/ResetPassword";
import OwnerPortal from "./pages/OwnerPortal";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <AuthProvider>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Routes>
            {/* Public customer-facing routes */}
            <Route path="/" element={<LandingPage />} />
            <Route path="/explore" element={<Explore />} />
            <Route path="/property/:propertyId" element={<PropertyDetail />} />
            <Route path="/capture" element={<LeadCapture />} />
            <Route path="/auth" element={<Auth />} />
            <Route path="/reset-password" element={<ResetPassword />} />

            {/* Owner-facing portal */}
            <Route
              path="/owner-portal"
              element={
                <AuthGuard allowedRoles={['admin', 'owner']}>
                  <OwnerPortal />
                </AuthGuard>
              }
            />

            {/* Internal CRM routes - Restricted to staff */}
            <Route path="/dashboard" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Dashboard /></AuthGuard>} />
            <Route path="/leads" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Leads /></AuthGuard>} />
            <Route path="/pipeline" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Pipeline /></AuthGuard>} />
            <Route path="/visits" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Visits /></AuthGuard>} />
            <Route path="/conversations" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Conversations /></AuthGuard>} />
            <Route path="/analytics" element={<AuthGuard allowedRoles={['admin', 'manager']}><Analytics /></AuthGuard>} />
            <Route path="/historical" element={<AuthGuard allowedRoles={['admin', 'manager']}><Historical /></AuthGuard>} />
            <Route path="/settings" element={<AuthGuard allowedRoles={['admin', 'manager']}><SettingsPage /></AuthGuard>} />
            <Route path="/owners" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Owners /></AuthGuard>} />
            <Route path="/inventory" element={<AuthGuard allowedRoles={['admin', 'manager']}><Inventory /></AuthGuard>} />
            <Route path="/effort" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><EffortDashboard /></AuthGuard>} />
            <Route path="/availability" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Availability /></AuthGuard>} />
            <Route path="/matching" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Matching /></AuthGuard>} />
            <Route path="/bookings" element={<AuthGuard allowedRoles={['admin', 'manager', 'agent']}><Bookings /></AuthGuard>} />
            <Route path="/zones" element={<AuthGuard allowedRoles={['admin', 'manager']}><ZoneManagement /></AuthGuard>} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </AuthProvider>
  </QueryClientProvider>
);

export default App;
