-- EVRYLUX - custo-base de cripto por ativo
alter table public.finance_data
  add column if not exists bitcoin_invested double precision not null default 0,
  add column if not exists ethereum_invested double precision not null default 0,
  add column if not exists solana_invested double precision not null default 0,
  add column if not exists usdt_invested double precision not null default 0;

alter table public.finance_data
  drop constraint if exists finance_data_bitcoin_invested_nonnegative,
  add constraint finance_data_bitcoin_invested_nonnegative check (bitcoin_invested >= 0),
  drop constraint if exists finance_data_ethereum_invested_nonnegative,
  add constraint finance_data_ethereum_invested_nonnegative check (ethereum_invested >= 0),
  drop constraint if exists finance_data_solana_invested_nonnegative,
  add constraint finance_data_solana_invested_nonnegative check (solana_invested >= 0),
  drop constraint if exists finance_data_usdt_invested_nonnegative,
  add constraint finance_data_usdt_invested_nonnegative check (usdt_invested >= 0);
