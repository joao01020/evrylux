import {
  createClient,
  type SupabaseClient,
} from '@supabase/supabase-js';

const supabaseUrl =
  import.meta.env.PUBLIC_SUPABASE_URL?.trim();

const supabasePublishableKey =
  import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();

if (!supabaseUrl) {
  throw new Error(
    'PUBLIC_SUPABASE_URL não foi definido.',
  );
}

if (!supabasePublishableKey) {
  throw new Error(
    'PUBLIC_SUPABASE_PUBLISHABLE_KEY não foi definido.',
  );
}

export const supabase: SupabaseClient =
  createClient(
    supabaseUrl,
    supabasePublishableKey,
    {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    },
  );
