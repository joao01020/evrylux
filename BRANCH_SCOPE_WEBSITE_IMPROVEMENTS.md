# Branch Scope — feature/website-improvements

## Objetivo

Esta branch tem como objetivo aperfeiçoar exclusivamente o website do projeto
EVRYLUX.

O foco será melhorar a apresentação, usabilidade, performance, clareza das
informações e experiência geral do visitante, sem misturar mudanças do
aplicativo principal, Brain, sincronização, Vault ou outras áreas internas do
sistema.

---

## Escopo principal

### 1. Melhorias visuais

Aperfeiçoar a identidade visual do site sem perder consistência com o restante
do projeto.

Inclui:

- tipografia;
- espaçamento;
- alinhamento;
- cores;
- hierarquia visual;
- cards;
- botões;
- ícones;
- seções;
- fundos;
- sombras;
- bordas;
- estados de hover;
- estados de foco;
- transições;
- animações leves.

Objetivo:

- deixar o site mais moderno;
- melhorar legibilidade;
- melhorar percepção de qualidade;
- evitar aparência genérica;
- manter consistência entre páginas.

---

## 2. Responsividade

Garantir boa experiência em diferentes tamanhos de tela.

Prioridades:

- desktop;
- notebook;
- tablet;
- celular.

Verificar:

- menus;
- cabeçalhos;
- grids;
- cards;
- textos;
- imagens;
- botões;
- formulários;
- tabelas;
- rodapé;
- modais.

Evitar:

- overflow horizontal;
- textos cortados;
- elementos sobrepostos;
- botões pequenos demais;
- espaçamentos inadequados.

---

## 3. Navegação

Melhorar a navegação do site.

Objetivos:

- tornar caminhos importantes mais claros;
- reduzir quantidade de cliques;
- melhorar menu principal;
- melhorar navegação mobile;
- deixar chamadas para ação mais fáceis de encontrar;
- garantir que o usuário saiba onde está.

Avaliar:

- navbar;
- menu mobile;
- links;
- breadcrumbs quando necessário;
- botões de voltar;
- navegação entre seções.

---

## 4. Página inicial

Refinar a homepage para comunicar rapidamente:

- o que é o EVRYLUX;
- para quem serve;
- quais problemas resolve;
- principais benefícios;
- como funciona;
- quais recursos possui;
- como começar.

A página inicial deve priorizar clareza e conversão.

Possíveis seções:

- Hero;
- proposta de valor;
- funcionalidades;
- benefícios;
- demonstrações;
- screenshots;
- como funciona;
- planos;
- perguntas frequentes;
- chamada para ação final.

---

## 5. Textos e comunicação

Revisar textos do website para melhorar:

- clareza;
- objetividade;
- consistência;
- compreensão;
- tom;
- chamadas para ação.

Evitar:

- textos excessivamente técnicos para visitantes comuns;
- frases genéricas;
- promessas exageradas;
- informações repetidas.

Priorizar:

- benefícios concretos;
- explicações simples;
- mensagens curtas;
- CTAs claros.

---

## 6. Planos e preços

Se houver página de planos ou assinatura, melhorar:

- comparação entre planos;
- clareza de benefícios;
- destaque de diferenças;
- preço;
- periodicidade;
- limitações;
- chamadas para ação.

Evitar informações ambíguas.

O usuário deve entender facilmente:

- o que recebe;
- quanto custa;
- qual plano atende melhor cada necessidade.

---

## 7. Formulários

Melhorar formulários existentes.

Inclui:

- contato;
- cadastro;
- login;
- newsletter;
- demonstração;
- suporte;
- outros formulários do site.

Verificar:

- labels;
- placeholders;
- validação;
- mensagens de erro;
- loading;
- sucesso;
- acessibilidade;
- preenchimento mobile.

---

## 8. Performance

Melhorar desempenho do site sempre que possível.

Analisar:

- imagens grandes;
- assets desnecessários;
- fontes;
- scripts;
- carregamento inicial;
- componentes pesados;
- chamadas de rede;
- lazy loading;
- cache.

Objetivos:

- reduzir tempo de carregamento;
- diminuir tamanho de página;
- melhorar experiência em conexões mais lentas.

Não sacrificar estabilidade por otimizações prematuras.

---

## 9. SEO

Preparar o site para melhor indexação.

Verificar:

- title;
- meta description;
- headings;
- estrutura semântica;
- URLs;
- conteúdo;
- alt de imagens;
- Open Graph;
- sitemap;
- robots;
- canonical quando necessário.

Evitar técnicas artificiais ou spam.

---

## 10. Acessibilidade

Melhorar acessibilidade do website.

Prioridades:

- contraste;
- navegação por teclado;
- labels;
- foco visível;
- tamanho de fonte;
- semântica HTML;
- alt text;
- feedback de erro.

Sempre que possível, seguir boas práticas de acessibilidade web.

---

## 11. Estados de interface

Todas as páginas importantes devem considerar:

- loading;
- vazio;
- erro;
- sucesso;
- indisponibilidade;
- conteúdo parcial.

Evitar telas sem feedback.

---

## 12. Compatibilidade

Garantir compatibilidade razoável com navegadores modernos.

Priorizar:

- Chrome;
- Firefox;
- Edge;
- Safari.

Testar principalmente fluxos essenciais.

---

## 13. Organização do código

Durante as melhorias, preservar organização e legibilidade.

Evitar:

- componentes gigantes;
- CSS duplicado;
- estilos espalhados;
- lógica de negócio dentro de componentes visuais;
- nomes pouco claros;
- soluções temporárias sem necessidade.

Priorizar:

- componentes reutilizáveis;
- separação de responsabilidades;
- nomes claros;
- estilos consistentes;
- estrutura simples.

---

## 14. Segurança

Esta branch não deve enfraquecer segurança do projeto.

Não adicionar:

- chaves privadas;
- tokens;
- secrets;
- `.env` com dados sensíveis;
- credenciais;
- service keys.

Nunca expor informações internas do backend no frontend.

---

## 15. Integrações

Ao alterar integrações existentes:

- preservar contratos atuais;
- tratar erros;
- evitar chamadas duplicadas;
- evitar dependências desnecessárias;
- não quebrar autenticação;
- não quebrar formulários;
- não quebrar APIs existentes.

---

# Fora do escopo

Esta branch NÃO deve ser usada para mudanças grandes no aplicativo EVRYLUX.

Ficam fora do escopo:

- Brain;
- Vault;
- E2EE;
- SyncQueue;
- tombstones;
- remote GC;
- banco de dados do app;
- arquitetura interna do app;
- módulos de treino;
- alterações grandes no Flutter desktop;
- novos recursos complexos do Brain;
- refatorações profundas que não sejam necessárias para o website.

Se alguma mudança fora desse escopo for necessária, ela deve ser feita em outra
branch.

---

# Prioridades

## Prioridade alta

- corrigir problemas visuais;
- melhorar responsividade;
- melhorar homepage;
- melhorar navegação;
- melhorar textos;
- corrigir bugs;
- melhorar formulários;
- garantir boa experiência mobile.

## Prioridade média

- SEO;
- performance;
- acessibilidade;
- animações;
- refinamentos visuais.

## Prioridade baixa

- efeitos estéticos complexos;
- animações pesadas;
- mudanças que não tragam melhoria real de UX.

---

# Critérios de conclusão

A branch poderá ser considerada concluída quando:

- o site estiver visualmente consistente;
- estiver responsivo;
- não houver problemas graves de layout;
- navegação estiver clara;
- homepage estiver bem estruturada;
- textos estiverem revisados;
- formulários estiverem funcionando;
- principais páginas tiverem estados de erro/loading;
- performance estiver aceitável;
- SEO básico estiver configurado;
- não houver secrets expostos;
- funcionalidades existentes continuarem funcionando;
- mudanças estiverem testadas em desktop e mobile.

---

# Regra da branch

Antes de adicionar uma alteração, perguntar:

> Esta mudança melhora diretamente o website?

Se a resposta for não, provavelmente ela deve ser feita em outra branch.

---

# Nome da branch

```text
feature/website-improvements
```
