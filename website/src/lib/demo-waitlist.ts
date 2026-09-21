import {
  supabase,
} from './supabase';

export type DemoPlatform =
  | 'linux'
  | 'windows'
  | 'macos';

export type DemoInterest =
  | 'brain'
  | 'finance'
  | 'training'
  | 'routine'
  | 'all';

export type DemoWaitlistInput = {
  full_name: string;
  email: string;
  platform: DemoPlatform;
  interest: DemoInterest;
  willing_to_feedback: boolean;
};

export type DemoWaitlistEntry = {
  id: string;
  full_name: string;
  email: string;
  platform: DemoPlatform;
  interest: DemoInterest;
  willing_to_feedback: boolean;
  early_explorer: boolean;
  status: 'waiting' | 'invited' | 'testing';
  created_at: string;
  read_at: string | null;
};

export async function joinDemoWaitlist(
  input: DemoWaitlistInput,
) {
  const {
    data,
    error,
  } =
    await supabase
      .from('demo_waitlist')
      .insert({
        ...input,
        early_explorer:
          true,
      })
      .select('id')
      .single();

  if (error) {
    throw error;
  }

  return data;
}

export async function getDemoWaitlist() {
  const {
    data,
    error,
  } =
    await supabase
      .from('demo_waitlist')
      .select(
        'id, full_name, email, platform, interest, willing_to_feedback, early_explorer, status, created_at, read_at',
      )
      .order(
        'created_at',
        {
          ascending: false,
        },
      );

  if (error) {
    throw error;
  }

  return (
    data ?? []
  ) as DemoWaitlistEntry[];
}

export async function getUnreadDemoCount() {
  const {
    count,
    error,
  } =
    await supabase
      .from('demo_waitlist')
      .select(
        'id',
        {
          count: 'exact',
          head: true,
        },
      )
      .is(
        'read_at',
        null,
      );

  if (error) {
    throw error;
  }

  return count ?? 0;
}

export async function markDemoEntriesRead() {
  const {
    error,
  } =
    await supabase
      .from('demo_waitlist')
      .update({
        read_at:
          new Date().toISOString(),
      })
      .is(
        'read_at',
        null,
      );

  if (error) {
    throw error;
  }
}

export async function updateDemoStatus(
  id: string,
  status:
    | 'waiting'
    | 'invited'
    | 'testing',
) {
  const {
    error,
  } =
    await supabase
      .from('demo_waitlist')
      .update({
        status,
      })
      .eq(
        'id',
        id,
      );

  if (error) {
    throw error;
  }
}

export const demoPlatformLabel:
  Record<
    DemoPlatform,
    string
  > = {
    linux:
      'Linux',
    windows:
      'Windows',
    macos:
      'macOS',
  };

export const demoInterestLabel:
  Record<
    DemoInterest,
    string
  > = {
    brain:
      'Brain',
    finance:
      'Financeiro',
    training:
      'Treino',
    routine:
      'Rotina',
    all:
      'Quero explorar tudo',
  };
