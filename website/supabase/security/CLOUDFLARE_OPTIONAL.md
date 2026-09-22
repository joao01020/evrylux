# Camada opcional — Cloudflare

Supabase Auth deve ser a proteção principal do login. Como o site EVRYLUX usa Cloudflare
Pages, uma segunda camada na borda também é útil.

Se o plano/recursos disponíveis permitirem, considere:

- WAF gerenciado;
- proteção contra bots;
- rate limiting por IP para tráfego anormal;
- desafio para padrões claramente automatizados;
- regras mais rígidas em rotas públicas sujeitas a spam.

## Atenção sobre /login

O formulário `/login` chama o domínio do Supabase diretamente. Limitar apenas a URL
`/login` no Cloudflare protege a página, mas **não substitui o rate limit do Supabase Auth**,
porque um atacante pode chamar o endpoint de autenticação diretamente.

Por isso a ordem correta é:

1. Supabase Auth rate limit.
2. MFA/AAL2.
3. RLS/RPC no banco.
4. Cloudflare/WAF como camada complementar.
