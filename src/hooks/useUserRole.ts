
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export type AppRole = 'admin' | 'manager' | 'agent' | 'owner';

export function useUserRole() {
    const { user } = useAuth();

    return useQuery({
        queryKey: ['user-role', user?.id],
        enabled: !!user?.id,
        queryFn: async () => {
            const { data, error } = await supabase
                .from('user_roles' as any)
                .select('role')
                .eq('user_id', user!.id)
                .maybeSingle();

            if (error) throw error;
            return (data as any)?.role as AppRole | null;
        },
    });
}
