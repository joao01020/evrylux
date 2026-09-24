# refactor/app-performance

## Objetivo da branch

Esta branch existe para manter o EVRYLUX rápido, responsivo e eficiente durante
toda a evolução do projeto.

O foco principal é garantir que a inicialização do aplicativo continue rápida,
que operações pesadas não bloqueiem a interface e que o usuário perceba o app
como leve desde o primeiro segundo de uso.

Regra principal:

> Tudo que não for essencial para exibir a interface inicial deve, sempre que
> possível, ser carregado depois ou em background.

---

## Estado atual de performance

Antes das otimizações, a interface autenticada do EVRYLUX levava
aproximadamente:

- ~6,9 segundos para ser liberada

O principal motivo era que o aplicativo aguardava processos internos antes de
mostrar a interface, incluindo:

- inicialização autenticada
- ReviewRepository
- inicialização do dispositivo do Cérebro
- migrações
- E2EE
- sincronização
- carregamentos secundários

Depois das otimizações realizadas nesta branch, a interface autenticada passou a
ser liberada em aproximadamente:

- ~0,08 a 0,18 segundo
- melhor medição observada: ~80 ms

Isso representa uma redução aproximada de mais de 97% no tempo de espera do
AuthGate.

### Exemplo observado

Antes:

```text
[STARTUP][AUTH] +6920ms interface autenticada liberada
```

Depois:

```text
[STARTUP][AUTH] +80ms interface autenticada liberada
```

O primeiro frame global também passou a ficar em torno de:

```text
~1,4 a 1,7 segundo em ambiente de desenvolvimento/debug
```

Esse valor pode variar por causa de:

- hot restart
- modo debug
- acesso a disco
- cache
- rede
- compilação
- scheduler do Flutter
- carga da máquina

Por isso, a métrica mais importante para acompanhar é a percepção real de
abertura e o tempo até a interface ficar utilizável.

---

## Estratégia atual

A inicialização do EVRYLUX foi dividida em dois caminhos.

### Caminho crítico

Somente o necessário para abrir o aplicativo:

```text
main
↓
Flutter Binding
↓
Window
↓
.env
↓
Supabase
↓
Banco local
↓
Offline base
↓
runApp
↓
Sessão
↓
Perfil
↓
Interface
```

### Background

Processos que não precisam bloquear o usuário:

```text
ReviewRepository
↓
Brain Device
↓
Migrações
↓
E2EE
↓
SyncService
↓
Perfil remoto
↓
Atualizações
↓
ReminderService
↓
Device Presence
```

Esses processos continuam importantes, mas não devem impedir a abertura da
interface.

---

## Princípios desta branch

### 1. Inicialização rápida

- [x] Evitar operações pesadas antes do `runApp`
- [x] Não bloquear o AuthGate com E2EE
- [x] Não bloquear o AuthGate com SyncService
- [x] Evitar carregamentos remotos desnecessários na abertura
- [x] Liberar a interface assim que os dados essenciais estiverem disponíveis
- [x] Executar tarefas secundárias após o primeiro frame

### 2. Cache eficiente

O EVRYLUX deve priorizar dados locais sempre que possível.

Objetivo:

```text
abrir
↓
ler cache/local
↓
mostrar interface
↓
atualizar remoto em background
```

Evitar:

```text
abrir
↓
esperar servidor
↓
esperar rede
↓
mostrar interface
```

Checklist:

- [ ] Priorizar cache antes de chamadas remotas
- [ ] Evitar buscar novamente dados que já estão disponíveis localmente
- [ ] Definir TTL quando fizer sentido
- [ ] Invalidar cache somente quando necessário
- [ ] Evitar duplicação de requisições
- [ ] Compartilhar operações já em andamento
- [ ] Medir cache hit e cache miss
- [ ] Garantir funcionamento offline quando possível

### 3. Loading rápido e eficiente

Loadings devem existir somente quando realmente necessários.

Evitar:

- telas vazias por muito tempo
- spinner para dados que já existem em cache
- bloquear a tela inteira por uma operação secundária
- repetir loading em cada rebuild
- carregar dados invisíveis antes da tela principal

Priorizar:

- skeletons
- conteúdo local
- atualização progressiva
- loading apenas na região afetada
- tarefas em background
- interface utilizável enquanto dados secundários chegam

Checklist:

- [x] AuthGate não espera E2EE
- [x] Perfil da Welcome carrega após o primeiro frame
- [x] Conteúdo pesado invisível não é construído antecipadamente
- [ ] Revisar loaders globais
- [ ] Revisar loaders das telas principais
- [ ] Substituir loaders bloqueantes por carregamento progressivo quando
      possível
- [ ] Evitar flicker em atualizações rápidas

---

## Performance geral do app

Esta branch não é responsável somente pela abertura.

Também deve observar:

- tempo de navegação entre telas
- tempo de build dos widgets
- quantidade de rebuilds
- chamadas repetidas ao banco
- consultas remotas
- leitura e escrita em disco
- inicialização de controllers
- processamento síncrono pesado
- listas grandes
- animações
- uso de memória
- uso de CPU
- sincronização
- E2EE
- cache
- banco local

---

## Pontos para observar

### Startup

- [x] Tempo até `runApp`
- [x] Tempo do AuthGate
- [x] Tempo até interface autenticada
- [x] Tempo do primeiro frame
- [x] Tempo de carregamento do perfil
- [x] Tempo de inicialização offline
- [x] Tempo do AccountStartupCoordinator
- [x] Tempo do ReviewRepository
- [x] Tempo do Brain Device
- [x] Tempo de migração
- [x] Tempo do E2EE
- [x] Tempo do SyncService

### Perfil

- [x] Evitar carregar o mesmo perfil duas vezes
- [x] Reutilizar carregamento em andamento
- [x] Usar cache/local primeiro
- [x] Atualizar perfil remoto em background
- [ ] Monitorar tempo médio do profile remoto
- [ ] Evitar rebuilds desnecessários após atualização

### Autenticação

- [x] Ignorar `initialSession` duplicada
- [x] Não executar `prepareUser` duas vezes
- [x] Não bloquear interface esperando processos internos
- [ ] Observar comportamento em login novo
- [ ] Observar comportamento em logout
- [ ] Observar troca de conta
- [ ] Observar sessão expirada
- [ ] Observar funcionamento offline

### Cérebro

- [x] E2EE fora do caminho crítico
- [x] Migração fora do caminho crítico
- [x] Device bootstrap fora do caminho crítico
- [ ] Criar sincronização incremental
- [ ] Evitar consultar todos os objetos quando nada mudou
- [ ] Criar checkpoint de sincronização
- [ ] Buscar somente objetos alterados
- [ ] Medir tempo de pull
- [ ] Medir número de objetos processados
- [ ] Observar impacto do crescimento do Vault

### Sincronização

- [x] SyncService inicia em background
- [ ] Evitar inicializações duplicadas
- [ ] Reduzir chamadas quando não existem itens pendentes
- [ ] Criar métricas de pending/ready
- [ ] Observar reconexão
- [ ] Observar comportamento offline → online
- [ ] Evitar sync desnecessário durante navegação

### Banco local

- [x] Banco inicializa rapidamente
- [x] Inicialização duplicada atualmente custa praticamente 0 ms após a primeira
      abertura
- [ ] Revisar queries lentas
- [ ] Criar índices quando necessário
- [ ] Medir queries críticas
- [ ] Evitar abrir banco repetidamente
- [ ] Evitar serializações grandes no startup

### Interface

- [x] WelcomeScreen não bloqueia o primeiro frame esperando perfil
- [x] Cards invisíveis não são construídos antes da hora
- [ ] Monitorar rebuilds
- [ ] Usar `const` sempre que possível
- [ ] Evitar widgets pesados no primeiro frame
- [ ] Evitar sombras/animações excessivas em listas grandes
- [ ] Revisar telas com muitos `setState`
- [ ] Revisar `LayoutBuilder` e árvores grandes
- [ ] Observar scroll e FPS

---

## Métricas atuais

### Antes

```text
Interface autenticada:
~6920 ms
```

### Depois

Melhor resultado observado:

```text
Interface autenticada:
~80 ms
```

Outros resultados observados:

```text
~87 ms
~137 ms
~179 ms
```

Isso é esperado em ambiente de desenvolvimento.

---

## E2EE

O E2EE ainda pode levar vários segundos em algumas inicializações.

Exemplos observados:

```text
~4,6 segundos
~5,4 segundos
~7,7 segundos
```

Porém ele atualmente executa em background.

Isso significa que:

```text
E2EE lento
≠
aplicativo lento para abrir
```

O usuário já consegue acessar a interface enquanto o E2EE termina internamente.

O próximo objetivo relacionado ao E2EE é melhorar eficiência, não bloquear
novamente a interface.

Possíveis melhorias futuras:

- [ ] Sincronização incremental
- [ ] Checkpoint remoto
- [ ] `lastSyncVersion`
- [ ] Buscar somente mudanças
- [ ] Evitar comparar todos os objetos
- [ ] Reduzir quantidade de round trips
- [ ] Medir latência de Supabase
- [ ] Analisar paginação
- [ ] Analisar payload
- [ ] Manter integridade e segurança atuais

---

## Regras para novas funcionalidades

Antes de adicionar algo ao startup, perguntar:

- [ ] Isso é realmente necessário antes da interface aparecer?
- [ ] Isso pode ser executado depois do primeiro frame?
- [ ] Existe cache local?
- [ ] Estamos esperando a rede sem necessidade?
- [ ] Essa operação já está sendo executada em outro lugar?
- [ ] É possível reutilizar uma Future já em andamento?
- [ ] Isso pode causar rebuild global?
- [ ] Isso precisa bloquear a tela inteira?
- [ ] O usuário precisa esperar isso para usar o app?
- [ ] Foi medido antes de otimizar?

Se a resposta indicar que a operação não é essencial, ela deve preferencialmente
ficar fora do caminho crítico.

---

## Logs de performance

Durante desenvolvimento, usar os logs:

```text
[STARTUP][MAIN]
[STARTUP][OFFLINE]
[STARTUP][APP]
[STARTUP][AUTH]
[STARTUP][COORDINATOR]
[STARTUP][ACCOUNT]
[STARTUP][WELCOME]
```

Eles ajudam a identificar exatamente onde o tempo está sendo gasto.

Exemplo:

```text
[STARTUP][AUTH] +80ms interface autenticada liberada
[STARTUP][WELCOME] +512ms primeiro frame da Welcome renderizado
[STARTUP][ACCOUNT] +5715ms Brain E2EE bootstrap
```

A leitura correta é:

```text
interface disponível rapidamente
+
processos internos continuam em background
```

---

## Meta permanente

A meta desta branch é manter o EVRYLUX com sensação de resposta imediata.

Não existe um número único que deve ser perseguido em qualquer máquina, mas
algumas referências desejadas são:

```text
AuthGate:
< 250 ms quando existe sessão e cache local

Interface:
mostrar o mais cedo possível

Operações remotas:
não bloquear a interface quando não forem essenciais

Background:
executar sem prejudicar interação, FPS ou estabilidade
```

---

## Critérios para considerar uma mudança aprovada

Uma alteração de performance só deve ser considerada concluída quando:

- [ ] Não introduzir regressões funcionais
- [ ] Não enfraquecer E2EE ou segurança
- [ ] Não causar perda de dados
- [ ] Não quebrar offline-first
- [ ] Não duplicar chamadas
- [ ] Não aumentar significativamente o startup
- [ ] Não criar loading desnecessário
- [ ] Não causar flicker
- [ ] Não causar rebuild excessivo
- [ ] Passar no `flutter analyze`
- [ ] Funcionar após restart completo
- [ ] Funcionar em sessão já autenticada
- [ ] Funcionar em login novo
- [ ] Funcionar offline quando aplicável

---

## Comandos úteis

### Rodar análise

```bash
flutter analyze
```

### Executar no Linux

```bash
flutter run -d linux
```

### Filtrar logs de startup

```bash
flutter run -d linux 2>&1 | grep "\[STARTUP\]"
```

### Procurar operações potencialmente pesadas

```bash
grep -RIn \
  --include="*.dart" \
  "await " \
  lib
```

### Ver estado da branch

```bash
git status
```

---

## Branch

```text
refactor/app-performance
```

Responsabilidade:

```text
Startup
Cache
Loading
Responsividade
Performance
Eficiência
Uso de recursos
Experiência de abertura
```

Esta branch deve continuar sendo utilizada para analisar, medir e melhorar a
velocidade do EVRYLUX sem sacrificar segurança, consistência, offline-first ou
integridade dos dados.
