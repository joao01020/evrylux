import { supabase } from './supabase';

export type MfaAalState = {
  currentLevel: 'aal1' | 'aal2' | null;
  nextLevel: 'aal1' | 'aal2' | null;
};

export async function getMfaAalState(): Promise<MfaAalState> {
  const { data, error } =
    await supabase.auth.mfa.getAuthenticatorAssuranceLevel();

  if (error) {
    throw error;
  }

  return {
    currentLevel: data.currentLevel ?? null,
    nextLevel: data.nextLevel ?? null,
  };
}

export async function getVerifiedTotpFactor() {
  const { data, error } =
    await supabase.auth.mfa.listFactors();

  if (error) {
    throw error;
  }

  return (
    data.totp?.find(
      (factor) => factor.status === 'verified',
    ) ?? null
  );
}

export async function hasAdminRole(): Promise<boolean> {
  const { data, error } =
    await supabase.rpc('has_colab_admin_role');

  if (error) {
    throw error;
  }

  return data === true;
}

export async function requireAal2(options?: {
  next?: string;
}): Promise<boolean> {
  const { data, error } =
    await supabase.auth.getSession();

  if (error || !data.session) {
    if (typeof window !== 'undefined') {
      const next =
        options?.next ??
        window.location.pathname + window.location.search;

      window.location.href =
        `/login?next=${encodeURIComponent(next)}`;
    }

    return false;
  }

  const state =
    await getMfaAalState();

  if (state.currentLevel === 'aal2') {
    return true;
  }

  if (typeof window !== 'undefined') {
    const next =
      options?.next ??
      window.location.pathname + window.location.search;

    window.location.href =
      `/colab/security?next=${encodeURIComponent(next)}`;
  }

  return false;
}

export async function requireAdminAal2(options?: {
  next?: string;
}): Promise<boolean> {
  const aal2 =
    await requireAal2(options);

  if (!aal2) {
    return false;
  }

  const { data, error } =
    await supabase.rpc('is_colab_admin');

  if (error || data !== true) {
    if (typeof window !== 'undefined') {
      window.location.href = '/colab';
    }

    return false;
  }

  return true;
}
