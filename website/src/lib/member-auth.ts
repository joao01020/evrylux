import {
  supabase,
} from './supabase';

export async function requireMemberSession() {
  const {
    data: {
      session,
    },
  } = await supabase.auth.getSession();

  if (!session) {
    window.location.replace(
      '/login',
    );

    return null;
  }

  return session;
}

export async function redirectAuthenticatedMember() {
  const {
    data: {
      session,
    },
  } = await supabase.auth.getSession();

  if (session) {
    window.location.replace(
      '/members',
    );

    return true;
  }

  return false;
}

export async function signOutMember() {
  await supabase.auth.signOut();

  window.location.replace(
    '/login',
  );
}
