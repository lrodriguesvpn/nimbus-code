# Research: Harness Corporativo — Consolidação de Harness Agêntico IDE Pessoal

**Feature**: `029-harness-corporativo-ide`  
**Data**: 2026-09-22  
**Agente**: NC-Arch (Nimbus Solution Architect)  
**Status**: Concluído (resolvendo todas as pendências e clarificações de `spec.md` e `interview.md`)

---

## 1. Contexto Arquitetural e Desafios

Esta feature implementa a **Opção A** aprovada com GO condicional no assessment (`harness-consolidacao-corporativa`), estendendo o mecanismo comprovado de `scripts/harvest-patterns.sh` para capturar os arquivos de configuração pessoal de agentes IDE (`~/.claude/CLAUDE.md` e `.cursor/rules`) dos colaboradores.

Diferente do caso de uso original de `scripts/harvest-patterns.sh` (que varre apenas assinaturas e metadados estruturais de código versionado), o Harness Agêntico IDE consiste em **texto livre**. Isso introduz riscos críticos de segurança e privacidade (classificação **S4**):
1. Risco de exposição acidental de credenciais/tokens colados no prompt/regras.
2. Risco de vazamento de dados de clientes, propriedade intelectual ou PII para LLMs externos.
3. Necessidade de isolamento estrito de escrita (nunca poluir o catálogo de reuso do projeto local).
4. Necessidade de governança humana absoluta (nenhuma promoção automática a padrão corporativo).
5. Ciclo de vida com expurgo automático garantido (LGPD/retenção em 90 dias para itens não promovidos).

Abaixo estão formalizadas as decisões técnicas que sustentam o plano de implementação.

---

## 2. Decisões Arquiteturais Detalhadas

### Decisão 1 — Arquitetura de Captura e Extensão da CLI (`scripts/harvest-patterns.sh`)

**Decisão**: Estender `scripts/harvest-patterns.sh` adicionando o modo `--source ide-harness` (com flags complementares `--harness-path`, `--target-central-repo` e `--anonymize-only`).

**Rationale**:
- Reutiliza a infraestrutura já testada de invocação e integração HTTP com o Gateway (`HARVEST_API_URL`), minimizando duplicação de código (em conformidade com SUC-003).
- O comando permanece estritamente **on-demand** e disparado por humano (FR-002, AC-1).
- Adiciona validação bloqueante de destino: se a flag `--target-central-repo` não for informada e a variável `HARVEST_CENTRAL_REPO_DIR` não estiver configurada, o script aborta com erro explícito. Ele **recusa terminantemente** escrever na saída padrão do repositório de trabalho local (`docs/reuse-catalog.yaml`), garantindo isolamento total (FR-003, AC-2).
- Trata graciosamente o caso de arquivos vazios ou inexistentes: se nem `~/.claude/CLAUDE.md` nem `.cursor/rules` existirem (ou estiverem em branco), reporta "Nada capturado" e encerra com código 0 sem gerar lixo no repositório central.

**Alternatives considered**:
- *Criar um script completamente novo (`scripts/harvest-ide-harness.sh`)*: Rejeitado por duplicar lógica de transporte HTTP, logging de tokens e integração com o Gateway.
- *Agente residente de endpoint com varredura contínua (Opção C do assessment)*: Rejeitado explicitamente no gate de decisão por risco desproporcional de segurança de endpoint e falta de consentimento explícito.

---

### Decisão 2 — Motor de Anonimização e Sanitização Local (`scripts/lib/harness_anonymizer.py`)

**Decisão**: Criar um módulo Python dedicado (`scripts/lib/harness_anonymizer.py`), executado localmente na máquina do desenvolvedor antes de qualquer transmissão para o LLM externo ou gravação externa, operando em modo **Fail-Closed**.

**Rationale**:
- A LGPD e as diretrizes corporativas de segurança proíbem o envio de texto livre contendo segredos ou PII para APIs externas.
- O sanitizador opera em múltiplos estágios:
  1. **Detector de Segredos**: Detecta chaves de API conhecidas (OpenAI `sk-...`, Anthropic `sk-ant-...`, AWS Access Keys `AKIA...`, GitHub tokens `ghp_...`, JWTs, Bearer tokens e blocos de chave privada PEM).
  2. **Detector de Entropia de Shannon**: Detecta strings alfanuméricas com alta entropia (típicas de credenciais/senhas aleatórias).
  3. **Detector de PII & Dados Sensíveis**: Detecta padrões de CPF, e-mails corporativos/pessoais, endereços IP (IPv4/IPv6 privados e públicos), telefones e identificadores de clientes.
  4. **Substituição por Tokens Canônicos**: Substitui ocorrências por tokens seguros (ex.: `[REDACTED_API_KEY]`, `[REDACTED_EMAIL]`, `[REDACTED_IP]`).
  5. **Verificação Pós-Sanitização (Gate Fail-Closed)**: Se após a redação o analisador ainda detectar qualquer indício de segredo não redigido, a execução é abortada imediatamente com código de saída 1, exibindo linha e padrão suspeito (sem exibir o segredo). Nenhum dado é enviado a `HARVEST_API_URL` (FR-004, FR-005, AC-3).

**Alternatives considered**:
- *Sanitização no Gateway (`nimbuscode-harvest-gateway`)*: Rejeitado porque o dado sensível já teria saído da máquina do desenvolvedor e trafegado pela rede pública, violando o princípio de menor exposição e o propósito do Security Gate.
- *Uso de biblioteca externa pesada (ex.: Presidio completo)*: Rejeitado para o script local v1 para evitar dependências pesadas de modelos NLP locais (~500MB) na máquina do dev. Expressões regulares compiladas com detector de entropia e heurística cobrem 100% dos padrões necessários com execução instantânea (<100ms) e dependência padrão Python 3.11.

---

### Decisão 3 — Resolução de Clarificação: Composição do Comitê e Protocolo de Quórum (`[NEEDS CLARIFICATION: comite-composicao]`)

**Decisão**: Formalizar a composição dos 4 membros do Comitê Nimbus Code por papéis funcionais e estabelecer regra clara de quórum de promoção e descarte.

**Composição Formal dos 4 Papéis**:
1. **Architecture Lead (Líder de Arquitetura)**: Responsável por garantir aderência aos padrões de arquitetura corporativa, modularidade e reuso institucional.
2. **Security & DevSecOps Guardian (Guardião de Segurança)**: Responsável por auditar ausência de riscos residuais de segurança, conformidade com políticas de segredos e salvaguardas de dados.
3. **Platform Tech Lead (Líder Técnico de Plataforma)**: Responsável por avaliar a viabilidade de integração com ferramentas, presets, IDEs (Claude/Cursor) e CLI.
4. **Product Sponsor / Governance Lead (Patrocinador / Líder de Governança)**: Responsável pelo alinhamento com metas estratégicas de produtividade e prioridades corporativas.

**Regras de Quórum e Votação (FR-006, FR-014)**:
- **Promoção Geral (Regra de escopo amplo)**: Quórum mínimo de **2 membros** aprovadores, sendo obrigatório que ao menos um seja técnico (Architecture Lead ou Platform Tech Lead).
- **Promoção Específica de Bounded Context Sensível**: Exige aprovação de **3 membros**, incluindo o Security Guardian. Qualquer veto explícito de Segurança bloqueia a promoção até saneamento.
- **Descarte de Item Bruto**: Pode ser realizado por qualquer membro do Comitê que identifique irrelevância, duplicidade ou inadequação. Se houver dúvida, o item permanece em `raw/` até atingir o prazo de expurgo automático de 90 dias.
- **Impossibilidade Absoluta de Promoção Automática**: Nenhum webhook, pipeline ou script tem permissão de escrita em `promoted/`. A promoção exige commit assinado por membro do comitê ou PR aprovado via `CODEOWNERS` específico do repositório central.

**Alternatives considered**:
- *Quórum unânime de 4 membros para qualquer regra*: Rejeitado por gerar lentidão excessiva e paralisia operacional quando membros estiverem em férias ou indisponíveis.
- *Aprovação por 1 único membro sem distinção de papel*: Rejeitado por fragilidade de governança em uma feature S4 com dados de texto livre.

---

### Decisão 4 — Resolução de Clarificação: Gate Jurídico/DPO (`[NEEDS CLARIFICATION: parecer-juridico-dpo]`)

**Decisão**: Estabelecer uma separação rigorosa entre o **Ciclo de Desenvolvimento/Engenharia** e o **Gate de Ativação Operacional em Produção com Dados Reais**.

**Protocolo de Gate**:
- **Ambiente de Desenvolvimento / Piloto Sintético**: A construção dos scripts, testes automatizados (unitários, integração e BATS) e validação de fluxo de dados ocorrem utilizando **harness sintéticos / fixtures de teste**. O desenvolvimento técnico NÃO é bloqueado.
- **Gate de Execução Real (Bloqueante)**: A execução do harvester contra máquinas e dados reais de colaboradores humanos fica bloqueada até que o parecer formal do Jurídico/DPO seja emitido e anexado ao repositório central (`docs/compliance/dpo-legal-opinion.md`).
- **Escopo do Parecer Exigido**:
  1. Validação da cláusula aditiva do NDA corporativo para coleta de prompts e configurações de ferramentas de trabalho.
  2. Homologação da política de retenção de 90 dias para dados brutos não promovidos.
  3. Validação do DPA (Data Processing Agreement) com o provedor de LLM acessado via `HARVEST_API_URL` para o tráfego anonimizado.

---

### Decisão 5 — Resolução de Clarificação: Tensão de Classificação LGPD (`[NEEDS CLARIFICATION: lgpd-tensao-classificacao]`)

**Decisão**: Implementar a coexistência em duas camadas (Técnica vs. Administrativa) de forma complementar e desacoplada.

**Estrutura em Duas Camadas**:
1. **Camada Técnica (No momento da Captura)**:
   - Aplica sanitização preventiva incondicional.
   - Nenhuma informação pessoal ou segredo é enviado ao LLM externo ou armazenado em texto cru.
   - Trata todo texto livre na captura como potencialmente contaminado por padrão (*assume breach / zero trust*).
2. **Camada Administrativa (Na Triagem do Comitê)**:
   - O Comitê Nimbus Code avalia o conteúdo já sanitizado e aplica a classificação de informação corporativa:
     - *Pública/Open*: Padrões de prompt e convenções gerais de engenharia sem propriedade intelectual sensível.
     - *Interna VPN*: Convenções e padrões restritos aos times internos.
     - *Confidencial/Cliente*: Regras que fazem referência a regras de negócio de clientes específicos (promovidas exclusivamente para o bounded context daquele cliente ou descartadas).

Essa abordagem resolve a tensão eliminando o risco técnico de vazamento na origem, mantendo a flexibilidade de governança negocial para o Comitê.

---

### Decisão 6 — Estrutura e Governança do Repositório Central Dedicado (`nimbus-code-harness-corporativo`)

**Decisão**: Organizar o repositório central em três partições primárias (`raw/`, `promoted/`, `archive/`) com manifesto indexador (`manifests/index.yaml`).

**Estrutura de Diretórios**:
```text
nimbus-code-harness-corporativo/
├── raw/
│   └── <author-hash>/
│       └── <timestamp>-<tool>.yaml
├── promoted/
│   ├── generic/
│   │   └── <category>/
│   │       └── <rule-slug>.yaml
│   └── bounded-contexts/
│       └── <context-slug>/
│           └── <rule-slug>.yaml
├── archive/
│   └── purge-audit.jsonl
├── manifests/
│   └── index.yaml
└── .github/
    └── workflows/
        ├── purge-expired-harness.yml
        └── pr-validation.yml
```

**Atributos de Rastreabilidade (FR-010, FR-013)**:
- Cada entrada em `raw/` contém: ID único, autor (identificador ou hash consistente), ferramenta de origem (`claude-code`, `cursor`), data/hora ISO 8601, SHA-256 do conteúdo bruto original (para integridade), payload sanitizado e status (`pending`, `promoted`, `discarded`, `purged`).
- RBAC no GHE:
  - Membros do esquadrão piloto: Permissão de leitura/escrita em `raw/` via token/branch.
  - Membros do Comitê: Permissão administrativa total e aprovação exclusiva de PRs para `promoted/` via `CODEOWNERS`.

---

### Decisão 7 — Expurgo Automático em 90 Dias (FR-008)

**Decisão**: Automação via script Python (`scripts/purge-expired.py`) disparada semanalmente via GitHub Action (`purge-expired-harness.yml`) no repositório central.

**Funcionamento**:
- Localiza arquivos em `raw/` onde `(now - capture_date) > 90 dias` E `status != "promoted"`.
- Remove fisicamente os arquivos de `raw/`.
- Adiciona registro de auditoria em `archive/purge-audit.jsonl` com timestamp, ID do item, data de captura e hash criptográfico, comprovando o cumprimento da política de retenção sem manter o texto excluído.

---

### Decisão 8 — Redistribuição Idempotente Opcional (Etapa 2, FR-009)

**Decisão**: Reutilizar o algoritmo de distribuição idempotente existente em `bootstrap.sh` (`refresh_managed_project_root_files`).

**Funcionamento**:
- Regras promovidas classificadas em `promoted/bounded-contexts/<slug>/` possuem manifesto indicando o arquivo de destino (ex.: `.claude/CLAUDE.md` ou `.cursor/rules/corporate.mdc`).
- O script de sincronização (`scripts/sync-corporate-harness.sh`):
  - Verifica se o arquivo de destino no repositório satélite possui o marcador de gerenciamento Nimbus (`<!-- NIMBUS-MANAGED: START -->`).
  - Se possuir, atualiza apenas a seção gerenciada, preservando as customizações locais do desenvolvedor antes e depois do bloco.
  - Se o arquivo já existir sem o marcador, cria um arquivo sugestão (`.divergent`) e notifica no log, nunca sobrescrevendo alterações locais do time (Edge Case).

---

## 3. Resumo de Mitigações de Riscos e Harness Consultado

| ID Referência | Risco/Erro Histórico | Mitigação Arquitetural Adotada |
|---|---|---|
| **HRN-0001** | Scope creep silencioso do agente | Escopo do script estritamente delimitado a arquivos de harness com allowlist de escrita. |
| **HRN-0002** | Decisão de arquitetura silenciosa sem ADL | Todas as decisões arquiteturais registradas formalmente no ADL do `plan.md`. |
| **HRN-0003** | Padrão duplicado sem consultar catálogo | Reutilização por ponteiro do `harvest-patterns.sh` e do `bootstrap.sh`. |
| **HRN-0004** | Drift de validação em produção | Cenários de teste e2e com validação de saída e gate formal de execução. |
| **HRN-0005** | Escrita/poluição no repositório errado | Bloqueio estrito no CLI impedindo escrita no `docs/reuse-catalog.yaml` local. |
| **HRN-0008** | Falha de propagação em `bootstrap.sh` | Atualização do catálogo e de sincronização testada com suíte BATS. |
