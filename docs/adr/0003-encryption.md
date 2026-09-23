# ADR 0003 — Criptografia e E2EE

- Status: Aceito
- Data: 2026-09-23

## Contexto

O projeto pode armazenar conteúdo sensível que necessita de proteção adicional
contra acesso indevido.

Criptografia em trânsito, como TLS, protege os dados durante a comunicação.

Criptografia em repouso no servidor protege determinados cenários relacionados
ao armazenamento físico ou infraestrutura.

Essas proteções, isoladamente, não fornecem confidencialidade ponta a ponta.

Em um modelo E2EE, o conteúdo protegido deve ser criptografado antes de sair do
dispositivo do usuário e somente dispositivos autorizados devem possuir
capacidade de descriptografá-lo.

---

## Decisão

Utilizar uma camada de criptografia no cliente para dados classificados como
E2EE.

Fluxo de envio:

```text
Conteúdo em plaintext
        ↓
Criptografia no cliente
        ↓
Ciphertext
        ↓
Persistência / Sync
        ↓
Backend
```

Fluxo de leitura:

```text
Backend
   ↓
Ciphertext
   ↓
Cliente autorizado
   ↓
Decrypt
   ↓
Conteúdo em plaintext
```

O backend deve armazenar ciphertext para os campos classificados como protegidos
por E2EE.

---

## Objetivo de segurança

O objetivo principal é reduzir a capacidade do backend ou de um vazamento
isolado do banco de revelar diretamente o conteúdo protegido.

E2EE não substitui:

- autenticação;
- autorização;
- RLS;
- segurança do dispositivo;
- proteção de sessão;
- backup;
- controle de acesso;
- segurança operacional.

Essas camadas continuam necessárias.

---

## Escopo

Nem todo dado precisa necessariamente utilizar E2EE.

Os dados devem ser classificados antes da implementação.

Exemplo conceitual:

```text
Metadado operacional
→ pode não exigir E2EE

Conteúdo privado do Brain
→ candidato a E2EE

Senha
→ não deve ser armazenada pelo aplicativo

Token de sessão
→ possui mecanismo próprio de proteção
```

A classificação real deve ser documentada conforme a arquitetura evoluir.

---

## Dados protegidos

Para cada modelo, deve ficar definido quais campos são:

```text
plaintext permitido

metadado necessário ao sync

ciphertext

informação derivada

secret
```

Evite criptografar indiscriminadamente campos necessários para:

- ownership;
- RLS;
- sincronização;
- integridade;
- roteamento;
- identificação estrutural;

sem considerar o impacto arquitetural.

---

## Modelo de ameaça

A arquitetura busca reduzir riscos relacionados a cenários como:

- vazamento de banco;
- acesso indevido a backups remotos;
- leitura acidental de conteúdo privado por infraestrutura;
- exposição de registros armazenados no backend.

E2EE não protege automaticamente contra:

- dispositivo comprometido;
- malware no cliente;
- usuário autenticado e autorizado no próprio dispositivo;
- captura de tela;
- keylogger;
- código cliente malicioso executado antes da criptografia;
- perda ou comprometimento da chave local.

---

## Requisitos criptográficos

A implementação deve utilizar:

- algoritmo moderno;
- criptografia autenticada;
- biblioteca mantida;
- geração criptograficamente segura de chaves;
- nonce ou IV adequado;
- versionamento de formato;
- separação entre chave e ciphertext;
- autenticação de integridade;
- mecanismo de migração;
- estratégia de recuperação claramente definida.

---

## Criptografia autenticada

Sempre que aplicável, utilizar AEAD ou construção equivalente que forneça:

```text
Confidencialidade
+
Integridade
+
Autenticidade do ciphertext
```

A aplicação deve detectar corrupção ou alteração indevida do payload.

Um ciphertext inválido não deve ser tratado como conteúdo válido.

---

## Nonce / IV

O algoritmo escolhido deve utilizar nonce ou IV conforme suas especificações.

Regras:

- gerar conforme os requisitos do algoritmo;
- não reutilizar quando a construção proibir reutilização;
- armazenar o nonce junto aos metadados do payload quando isso for seguro e
  esperado;
- nunca substituir geração segura por valores previsíveis apenas por
  conveniência.

O nonce não precisa necessariamente ser secreto.

---

## Formato criptográfico

O payload criptografado deve possuir versão.

Exemplo conceitual:

```json
{
  "version": 1,
  "algorithm": "algoritmo-definido-pela-implementacao",
  "nonce": "...",
  "ciphertext": "..."
}
```

Os nomes e campos reais podem variar.

O objetivo é permitir evolução futura sem tornar dados antigos ilegíveis.

---

## Versionamento

Nunca assuma que o formato criptográfico atual será permanente.

A arquitetura deve permitir:

```text
v1
 ↓
v2
 ↓
v3
```

sem exigir perda de dados.

Mudanças podem envolver:

- algoritmo;
- derivação de chave;
- tamanho de chave;
- metadata;
- envelopes;
- estrutura do ciphertext.

---

## Gestão de chaves

Chaves criptográficas devem possuir ciclo de vida explícito.

O sistema deve considerar:

- geração;
- armazenamento;
- uso;
- backup quando aplicável;
- distribuição;
- revogação;
- rotação;
- recuperação;
- destruição.

A segurança da criptografia depende da segurança das chaves.

---

## Chaves no cliente

Chaves privadas do usuário não devem:

- estar hardcoded;
- ser commitadas;
- aparecer em logs;
- ser incluídas em `.env`;
- ser armazenadas em plaintext desnecessariamente;
- ser transmitidas ao backend sem proteção compatível com o modelo E2EE.

Quando possível, utilize mecanismos seguros disponibilizados pela plataforma
para armazenamento local de secrets.

---

## Backend

O backend não deve possuir acesso direto às chaves privadas necessárias para
descriptografar o conteúdo E2EE.

O backend pode armazenar:

- ciphertext;
- metadata;
- envelopes de chave;
- chaves públicas;
- identificadores;
- versões de formato;

quando isso fizer parte do protocolo definido.

Isso não deve conceder ao backend capacidade direta de recuperar o plaintext
protegido.

---

## Chaves administrativas

Chaves administrativas, como credenciais privilegiadas do backend, não devem
existir no aplicativo cliente.

Exemplos:

```text
service_role
database password
backend secret
private API credential
```

E2EE e credenciais administrativas são problemas distintos e devem permanecer
separados.

---

## Envelopes de chave

Quando aplicável, chaves de dados podem ser protegidas através de envelopes
associados a usuários ou dispositivos.

Fluxo conceitual:

```text
Data Encryption Key
        ↓
protegida para dispositivo A
        ↓
Key Envelope A

Data Encryption Key
        ↓
protegida para dispositivo B
        ↓
Key Envelope B
```

Essa arquitetura deve permitir:

- novos dispositivos;
- múltiplos dispositivos;
- revogação;
- rotação;
- migração;
- recuperação conforme política definida.

---

## Múltiplos dispositivos

Adicionar um novo dispositivo exige uma estratégia explícita para disponibilizar
as chaves necessárias.

Exemplo conceitual:

```text
Dispositivo existente
       ↓
autoriza novo dispositivo
       ↓
material de chave protegido
       ↓
novo dispositivo
```

O mecanismo final deve ser documentado antes da implementação definitiva.

Não envie simplesmente a chave privada em plaintext pelo backend.

---

## Revogação

Quando um dispositivo for removido ou comprometido, o sistema deve possuir uma
estratégia de revogação.

A revogação futura pode exigir:

- invalidar envelope;
- impedir novos acessos;
- gerar nova chave;
- recriptografar conteúdo;
- atualizar dispositivos autorizados.

A estratégia exata depende do modelo final de chaves.

---

## Rotação

A arquitetura deve permitir rotação de chaves.

Motivos possíveis:

- comprometimento;
- política de segurança;
- mudança de algoritmo;
- revogação de dispositivo;
- evolução do formato.

Fluxo conceitual:

```text
Chave antiga
    ↓
nova chave
    ↓
reproteção / migração
    ↓
versão atualizada
```

A rotação deve ser projetada para evitar perda de acesso aos dados.

---

## Recuperação

E2EE cria uma decisão importante:

```text
quem consegue recuperar uma chave perdida?
```

Quanto mais capacidade o servidor possui de recuperar a chave, menor pode ser a
garantia de E2EE dependendo da arquitetura utilizada.

Portanto, a estratégia de recuperação deve ser definida explicitamente.

Possibilidades futuras podem incluir:

- recovery key;
- dispositivo confiável existente;
- backup criptografado de chave;
- frase de recuperação;
- mecanismo de recuperação controlado pelo usuário.

A escolha deverá ser registrada quando o fluxo definitivo for implementado.

---

## Perda de chave

A perda das chaves necessárias pode significar perda permanente da capacidade de
descriptografar dados.

A interface deve evitar criar expectativa falsa de recuperação.

Se determinada configuração não permitir recuperação, isso deve ser informado
claramente ao usuário.

---

## Plaintext

Conteúdo em plaintext deve existir pelo menor tempo necessário.

Evite:

- persistir plaintext em arquivos temporários;
- registrar conteúdo em logs;
- manter cópias desnecessárias;
- incluir conteúdo protegido em crash reports;
- armazenar plaintext em cache não protegido sem necessidade.

---

## Persistência local

Offline-first exige armazenamento local.

Quando dados E2EE forem persistidos localmente, deve existir uma decisão
explícita sobre:

```text
plaintext local
ou
ciphertext local
```

Essa decisão deve considerar:

- segurança do dispositivo;
- experiência offline;
- performance;
- busca;
- recuperação;
- armazenamento seguro de chaves.

O fato de o backend armazenar ciphertext não significa automaticamente que todo
armazenamento local já está protegido.

---

## Offline-first

E2EE deve funcionar em conjunto com a decisão offline-first.

Fluxo esperado:

```text
Usuário cria conteúdo
       ↓
criptografia local
       ↓
persistência local
       ↓
UI
       ↓
sync posterior
       ↓
ciphertext remoto
```

A indisponibilidade do backend não deve impedir operações locais que possam ser
executadas com segurança.

Consulte:

```text
docs/adr/0001-offline-first.md
```

---

## Sincronização

O mecanismo de sync deve tratar ciphertext como parte do modelo persistido.

Sync não deve exigir descriptografar conteúdo no backend.

Quando possível:

```text
Cliente
   ↓
encrypt
   ↓
ciphertext
   ↓
sync
   ↓
Supabase
```

e:

```text
Supabase
   ↓
ciphertext
   ↓
sync
   ↓
Cliente
   ↓
decrypt
```

---

## Busca

E2EE limita determinadas formas de busca remota.

O backend não pode realizar busca normal sobre conteúdo que ele não consegue
descriptografar.

Possíveis abordagens incluem:

- índice local;
- metadata não sensível;
- busca no dispositivo;
- índices derivados cuidadosamente projetados.

Qualquer solução que revele informações derivadas do conteúdo deve ser avaliada
quanto à privacidade.

---

## IA

Se funcionalidades de IA precisarem processar conteúdo protegido por E2EE, isso
cria uma nova fronteira de confiança.

O sistema deve definir explicitamente:

- quais dados podem ser enviados;
- quando podem ser enviados;
- quanto contexto é necessário;
- qual provedor recebe;
- se há consentimento;
- como os dados são minimizados.

Quando possível, utilizar:

```text
retrieval local
      ↓
seleção mínima
      ↓
JSON compacto
      ↓
processamento necessário
```

em vez de transmitir o Brain inteiro.

E2EE não deve ser apresentado como proteção contra um serviço externo para o
qual o próprio cliente decidiu enviar plaintext.

---

## Metadata

Mesmo quando o conteúdo estiver criptografado, metadata pode revelar
informações.

Exemplos:

- timestamps;
- tamanho;
- frequência de alterações;
- IDs;
- relações;
- dispositivo;
- quantidade de registros.

A arquitetura deve minimizar metadata desnecessária quando possível.

---

## Migrations

Migrations que alteram dados criptografados exigem cuidado adicional.

O backend normalmente não poderá transformar semanticamente plaintext que não
conhece.

Algumas migrations podem exigir:

```text
backend marca necessidade
       ↓
cliente autorizado detecta
       ↓
decrypt local
       ↓
transformação
       ↓
encrypt novamente
       ↓
sync
```

Por isso, versionamento do formato é obrigatório.

---

## Backup

Backups remotos devem preservar ciphertext, não plaintext protegido.

Também deve ser considerada a recuperação das chaves.

Backup de ciphertext sem chave pode ser inutilizável.

Backup da chave sem proteção adequada pode comprometer a confidencialidade.

Os dois problemas devem ser tratados separadamente.

---

## Logging

Nunca registrar:

- chaves;
- private keys;
- recovery keys;
- plaintext sensível;
- secrets criptográficos;
- payload descriptografado completo;
- material temporário de derivação de chave.

Logs devem conter somente informações suficientes para diagnóstico.

---

## Tratamento de erros

Falhas criptográficas devem ser tratadas explicitamente.

Exemplos:

- chave ausente;
- chave incorreta;
- ciphertext corrompido;
- versão desconhecida;
- envelope inválido;
- autenticação do ciphertext falhou;
- dispositivo não autorizado.

Não tente retornar dados possivelmente corrompidos como se fossem válidos.

---

## Testes obrigatórios

A camada E2EE deve possuir testes específicos.

No mínimo:

- encrypt → decrypt;
- conteúdo vazio;
- conteúdo grande;
- caracteres Unicode;
- chave correta;
- chave incorreta;
- ciphertext alterado;
- nonce inválido;
- versão válida;
- versão desconhecida;
- reinicialização do aplicativo;
- persistência local;
- sync;
- múltiplos dispositivos;
- envelopes;
- recuperação quando implementada;
- rotação quando implementada.

---

## Testes de corrupção

Modificar qualquer parte autenticada do payload deve produzir falha de
verificação.

Exemplo:

```text
ciphertext original
       ↓
1 byte alterado
       ↓
decrypt
       ↓
FALHA
```

O sistema não deve retornar plaintext parcial ou silenciosamente aceitar
corrupção.

---

## Bibliotecas

Não implementar primitivas criptográficas manualmente.

Utilizar bibliotecas:

- reconhecidas;
- auditadas quando possível;
- mantidas;
- adequadas às plataformas suportadas.

Antes de trocar biblioteca criptográfica, avaliar compatibilidade com dados
existentes.

---

## Consequências positivas

- backend não precisa conhecer plaintext protegido;
- redução do impacto de determinados vazamentos de banco;
- maior privacidade;
- separação mais forte entre infraestrutura e conteúdo;
- proteção adicional para backups remotos;
- maior controle do usuário sobre os dados.

---

## Consequências negativas

- recuperação de conta fica mais complexa;
- perda de chave pode significar perda de dados;
- busca remota em plaintext fica limitada;
- sync fica mais complexo;
- migrations ficam mais complexas;
- múltiplos dispositivos exigem gestão de chaves;
- revogação exige arquitetura específica;
- suporte técnico possui menor capacidade de recuperar conteúdo;
- funcionalidades de IA podem exigir decisões adicionais de privacidade.

---

## Riscos principais

### Perda de chave

Pode tornar dados permanentemente inacessíveis.

Mitigação:

- estratégia de recuperação;
- UX clara;
- backups protegidos;
- testes.

### Chave exposta

Pode permitir acesso ao conteúdo protegido.

Mitigação:

- secure storage;
- ausência em logs;
- rotação;
- revogação.

### Nonce reutilizado

Dependendo do algoritmo, pode comprometer segurança.

Mitigação:

- seguir rigorosamente a construção utilizada;
- geração segura;
- testes.

### Implementação criptográfica incorreta

Pode fornecer falsa sensação de segurança.

Mitigação:

- não inventar criptografia;
- utilizar bibliotecas consolidadas;
- revisão especializada quando possível.

### Metadata

Conteúdo pode estar protegido enquanto metadata continua revelando padrões.

Mitigação:

- minimização;
- classificação;
- revisão de privacidade.

---

## Alternativas consideradas

### Apenas criptografia em trânsito

TLS protege comunicação, mas o backend ainda pode acessar o conteúdo após
recebê-lo.

Não atende ao objetivo de E2EE.

### Apenas criptografia em repouso no servidor

Protege determinados cenários de infraestrutura, mas o servidor ainda possui
capacidade de acessar o conteúdo.

Não atende ao objetivo de E2EE.

### Criptografia somente no backend

O backend receberia plaintext antes da criptografia.

Foi rejeitada para dados que exigem confidencialidade ponta a ponta.

### Criptografia própria

Foi rejeitada.

Construções criptográficas próprias aumentam significativamente o risco de
vulnerabilidades.

---

## Regras

- nunca inventar criptografia própria;
- utilizar primitivas modernas;
- utilizar bibliotecas mantidas;
- utilizar criptografia autenticada;
- seguir os requisitos de nonce/IV;
- não reutilizar nonce quando a construção não permitir;
- versionar o formato criptográfico;
- manter chaves separadas do ciphertext;
- nunca registrar chaves em logs;
- nunca colocar private keys no código;
- nenhuma chave administrativa deve estar no cliente;
- chaves privadas do usuário não devem ser entregues ao backend de forma que
  quebre o modelo E2EE;
- testar corrupção;
- testar perda de chave;
- planejar rotação;
- planejar recuperação;
- considerar múltiplos dispositivos;
- considerar offline-first;
- considerar impactos de busca e IA.

---

## Relação com outros documentos

Consulte:

```text
docs/ARCHITECTURE.md
docs/SECURITY_ARCHITECTURE.md
docs/TESTING.md
docs/TESTING_ROADMAP.md
docs/adr/0001-offline-first.md
docs/adr/0002-supabase.md
```

---

## Quando reconsiderar esta decisão

Esta decisão deve ser revisada se houver mudança relevante em:

- modelo de ameaça;
- requisitos de privacidade;
- algoritmo;
- biblioteca;
- arquitetura de chaves;
- recuperação;
- múltiplos dispositivos;
- utilização de IA;
- requisitos regulatórios;
- plataformas suportadas.

Mudanças substanciais devem gerar novo ADR ou substituir formalmente este
documento.

---

## Resultado

A camada de E2EE passa a ser tratada como componente arquitetural crítico.

O princípio esperado é:

```text
plaintext
   ↓
cliente autorizado
   ↓
criptografia
   ↓
ciphertext
   ↓
infraestrutura remota
```

e não:

```text
plaintext
   ↓
backend
   ↓
criptografia
```

para dados classificados como E2EE.

A implementação deve priorizar proteção real das chaves, compatibilidade com
offline-first, suporte a múltiplos dispositivos e capacidade de evolução do
formato criptográfico.

E2EE não deve existir apenas como característica declarada do produto.

Ele deve ser verificável através da arquitetura, implementação e testes.
