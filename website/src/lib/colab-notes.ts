import {
  supabase,
} from './supabase';

export type QuickNote = {
  id: string;
  title: string;
  content: string;
  created_by: string;
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
};

export type QuickNoteInput = {
  title: string;
  content: string;
  is_pinned: boolean;
};

const noteColumns =
  'id, title, content, created_by, is_pinned, created_at, updated_at';

export async function getQuickNotes() {
  const {
    data,
    error,
  } =
    await supabase
      .from('colab_quick_notes')
      .select(noteColumns)
      .order(
        'is_pinned',
        {
          ascending: false,
        },
      )
      .order(
        'updated_at',
        {
          ascending: false,
        },
      );

  if (error) {
    throw error;
  }

  return (
    data ?? []
  ) as QuickNote[];
}

export async function createQuickNote(
  input: QuickNoteInput,
  userId: string,
) {
  const {
    data,
    error,
  } =
    await supabase
      .from('colab_quick_notes')
      .insert({
        ...input,
        created_by:
          userId,
      })
      .select(noteColumns)
      .single();

  if (error) {
    throw error;
  }

  return data as QuickNote;
}

export async function updateQuickNote(
  id: string,
  input: QuickNoteInput,
) {
  const {
    data,
    error,
  } =
    await supabase
      .from('colab_quick_notes')
      .update({
        ...input,
        updated_at:
          new Date().toISOString(),
      })
      .eq(
        'id',
        id,
      )
      .select(noteColumns)
      .single();

  if (error) {
    throw error;
  }

  return data as QuickNote;
}

export async function deleteQuickNote(
  id: string,
) {
  const {
    error,
  } =
    await supabase
      .from('colab_quick_notes')
      .delete()
      .eq(
        'id',
        id,
      );

  if (error) {
    throw error;
  }
}
