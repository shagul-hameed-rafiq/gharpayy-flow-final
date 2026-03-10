
import { useAuth } from '@/contexts/AuthContext';
import { useUserRole, type AppRole } from '@/hooks/useUserRole';
import { Navigate, useLocation } from 'react-router-dom';
import { Loader2 } from 'lucide-react';

interface AuthGuardProps {
    children: React.ReactNode;
    allowedRoles?: AppRole[];
}

const AuthGuard = ({ children, allowedRoles }: AuthGuardProps) => {
    const { user, loading: authLoading } = useAuth();
    const { data: role, isLoading: roleLoading } = useUserRole();
    const location = useLocation();

    if (authLoading || roleLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-background">
                <Loader2 className="h-8 w-8 animate-spin text-accent" />
            </div>
        );
    }

    // Not logged in
    if (!user) {
        return <Navigate to="/auth" state={{ from: location }} replace />;
    }

    // Logged in but no role (should theoretically not happen if trigger works)
    if (!role && allowedRoles) {
        return <Navigate to="/" replace />;
    }

    // Role not allowed
    if (allowedRoles && !allowedRoles.includes(role as AppRole)) {
        // Redirect owners to owner portal if they try to access CRM
        if (role === 'owner' && location.pathname !== '/owner-portal') {
            return <Navigate to="/owner-portal" replace />;
        }
        // Redirect agents/managers to CRM if they try to access owner portal (optional, but good for UX)
        if (role !== 'owner' && location.pathname === '/owner-portal') {
            return <Navigate to="/dashboard" replace />;
        }

        return <Navigate to="/" replace />;
    }

    return <>{children}</>;
};

export default AuthGuard;
