-- ============================================================
-- EVRYLUX COLAB — FOTOS DE PERFIL
-- Execute no Supabase SQL Editor
-- ============================================================

-- Bucket público para avatares.
-- Limite: 5 MB.
-- Tipos permitidos: JPEG, PNG e WebP.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-avatars',
  'profile-avatars',
  true,
  5242880,
  array[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id)
do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;


-- Cada usuário só pode enviar arquivos para a própria pasta:
-- profile-avatars/<auth.uid()>/...

drop policy if exists
  "profile avatars insert own folder"
on storage.objects;

create policy
  "profile avatars insert own folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-avatars'
  and
  (storage.foldername(name))[1] = auth.uid()::text
);


drop policy if exists
  "profile avatars update own folder"
on storage.objects;

create policy
  "profile avatars update own folder"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-avatars'
  and
  (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile-avatars'
  and
  (storage.foldername(name))[1] = auth.uid()::text
);


drop policy if exists
  "profile avatars delete own folder"
on storage.objects;

create policy
  "profile avatars delete own folder"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profile-avatars'
  and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- O bucket é público apenas para leitura das fotos.
-- Upload/alteração/exclusão continuam protegidos pelas políticas acima.
