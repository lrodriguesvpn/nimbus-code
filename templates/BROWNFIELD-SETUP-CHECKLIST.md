<!--
  BROWNFIELD SETUP CHECKLIST
  
  Este arquivo é um template para ser copiado para o repositório do seu projeto.
  
  Instruções:
  1. Copie este arquivo para: .specify/BROWNFIELD-SETUP-CHECKLIST.md
  2. Preencha os espaços [PLACEHOLDER] com valores do seu projeto
  3. Use este checklist como guia para o primeiro ciclo Nimbus Code num repo existente
  4. Após completado, deixe este arquivo versionado no git como parte do histórico de setup
  
  Referência completa: https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/docs/brownfield-best-practices.md
-->

# Brownfield Setup Checklist — [PLACEHOLDER: nome do projeto]

Data de início: [PLACEHOLDER: data]
Dev responsável: [PLACEHOLDER: nome]
Status: ⏳ Em andamento

---

## Fase 1: Instalação do Nimbus Code

- [ ] Nimbus Code CLI (`specify`) instalado localmente e validado com `specify check`
- [ ] Repositório clonado em `[PLACEHOLDER: caminho local]`
- [ ] Executado: `cd [PLACEHOLDER: caminho] && curl -fsSL https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code/raw/main/bootstrap.sh | bash`
- [ ] Confirmado que o bootstrap criou `.specify/` e instalou o bundle padrão
- [ ] Se optamos por separar a inicialização: `specify init --here --integration copilot --force` executado antes do bootstrap
- [ ] GitHub Project V2 criado automaticamente pelo bootstrap (URL: [PLACEHOLDER: link do project])
- [ ] GitHub Project customizado conforme necessário (filtros, grupos, colunas)
- [ ] `.specify/` adicionado ao `.gitignore`? (se necessário) — ou, preferência: versione `.specify/features/`, ignore `.specify/memory/`
- [ ] README do projeto atualizado com a seção de Nimbus Code (copie de [`templates/README-bundle-section.md`](README-bundle-section.md))

## Fase 2: Análise do Código Existente (Derivar a Constituição)

- [ ] Estrutura de pastas e stack principal identificados
  - [ ] Stack de linguagens: [PLACEHOLDER: ex.: Python 3.11, TypeScript, Go]
  - [ ] Frameworks principais: [PLACEHOLDER: ex.: FastAPI, Next.js, Gin]
  - [ ] Padrões de testes observados: [PLACEHOLDER: ex.: pytest, Jest, GoTest]
  - [ ] Estrutura de módulos/pacotes: [PLACEHOLDER: ex.: monorepo, mono package, microserviços]

- [ ] Executado `/speckit.constitution` com o prompt de análise profunda (seção 2.3 do [developer-guide.md](../docs/developer-guide.md))
- [ ] Agente completou múltiplas iterações de análise (quantas: [PLACEHOLDER: 1-5])
- [ ] `constitution.md` gerado e revisado
- [ ] Ajustes manuais aplicados em `constitution.md`, se necessário (escreva resumo abaixo se sim)

**Observações sobre a constituição derivada:**
```
[PLACEHOLDER: resumo de qualquer ajuste manual ou observação interessante]
```

## Fase 3: Entender o Backlog (se aplicável)

- [ ] Existe backlog externo (Azure DevOps / JIRA)? [PLACEHOLDER: Sim/Não]
- [ ] Se Sim: MCP configurado para integração (ex.: `ado`, Atlassian Rovo)? [PLACEHOLDER: Sim/Não]
- [ ] Leitura prévia de cards recentes realizada (resumo de contexto):
  - [ ] Área/domínio do projeto: [PLACEHOLDER: ex.: billing, inventory, auth]
  - [ ] 3-5 cards/issues recentes anotados (linque-os ou resuma):
    ```
    [PLACEHOLDER: card ID, título, status]
    ```

## Fase 4: Primeira Feature com Nimbus Code

- [ ] Feature/card escolhido: [PLACEHOLDER: ex.: "PROJ-123 — Add user role management"]
- [ ] Executado `/speckit.specify` (com contexto de cards/constituição)
- [ ] `spec.md` gerado e revisado
- [ ] Executado `/speckit.plan` e revisado `plan.md`
  - [ ] Architecture Decision Log incluído com decisões-chave?
- [ ] Executado `/speckit.tasks` e revisado `tasks.md`
  - [ ] Tarefas estão em ordem de dependência?
  - [ ] Checklist de qualidade do preset incluído?
  - [ ] Itens de IaC obrigatório incluídos?

- [ ] Executado `/speckit.implement` — primeiras tarefas completadas
  - [ ] Quantos passes foram necessários? [PLACEHOLDER: 1-5]
  - [ ] Houve erros de compilação/teste? [PLACEHOLDER: Sim/Não — descreva se sim]
- [ ] Executado `/speckit.converge` — gaps identificados
  - [ ] Quantos gaps novos foram anexados? [PLACEHOLDER: número]
  - [ ] Natureza dos gaps (ex.: testes faltando, docs, edge cases): [PLACEHOLDER: resumo]

- [ ] Passes adicionais de `implement` → `converge` até ✅ **Converged** (quantos passes após o primeiro: [PLACEHOLDER])
- [ ] Código final validado (testes, compilação, cobertura)
- [ ] PR aberta e revisão de código completa (incluindo Copilot review obrigatória)
- [ ] Merge realizado

### Regra adicional para projetos multirepo

- [ ] Confirmado que o repositório atual é o **Repo Central** antes de criar/editar `specs/`
- [ ] Se este repo for satélite, nenhuma pasta `specs/` local foi criada
- [ ] Demandas originadas no satélite foram registradas no Repo Central antes do roteamento

## Fase 5: Documentação Pós-Setup

- [ ] Este checklist finalizado e commitado (git add `.specify/BROWNFIELD-SETUP-CHECKLIST.md`)
- [ ] Observações de aprendizados registradas abaixo
- [ ] README de desenvolvimento do projeto atualizado (se necessário)
- [ ] Equipe briefada sobre os padrões da constituição derivada

---

## Aprendizados e Observações

Use esta seção para anotar o que foi aprendido durante o setup, armadilhas encontradas,
ou notas para o próximo desenvolvedor que trabalhar neste projeto com Nimbus Code.

```
[PLACEHOLDER: notas de equipe]

Exemplo:
- Testes de integração eram frágeis no módulo X; adicionamos timeout e retry logic.
- O agente tentou usar padrão Y que não se aplica ao nosso stack; editamos constitution.md manualmente.
- Feature Z levou 3 passes de implement/converge antes de convergir — esperado, módulo legado complexo.
```

---

## Próximas Features

Após este setup, o próximo ciclo de Nimbus Code será:

1. Nova branch: `git checkout -b feature/[ID]-[descrição]`
2. `/speckit.specify` (usando contexto já aprendido em `constitution.md`)
3. `/speckit.plan` → `/speckit.tasks`
4. `/speckit.implement` → `/speckit.converge` (ciclos até ✅)
5. PR → Merge

Ver [`docs/developer-guide.md`](../docs/developer-guide.md) seção 3 para o passo a passo de importação de card, se aplicável.

Para referência completa de boas práticas e troubleshooting, ver [`docs/brownfield-best-practices.md`](../docs/brownfield-best-practices.md).

---

**Status Final**: ✅ Completo | ⏳ Em andamento | ❌ Bloqueado
