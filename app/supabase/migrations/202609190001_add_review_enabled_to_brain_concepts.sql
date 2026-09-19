-- EVRYLUX Brain — Fase 1 da revisão por conhecimento
-- Conhecimentos antigos permanecem fora das revisões por padrão.

alter table public.brain_concepts
  add column if not exists review_enabled boolean not null default false;
