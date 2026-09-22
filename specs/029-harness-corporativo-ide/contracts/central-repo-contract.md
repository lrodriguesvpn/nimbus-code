# Contrato de Repositório: `nimbus-code-harness-corporativo`

**Feature**: `029-harness-corporativo-ide`  
**Repositório Alvo**: `venha-pra-nuvem/nimbus-code-harness-corporativo`  
**Versão**: 1.0.0

---

## 1. Descrição e Responsabilidade

O repositório `nimbus-code-harness-corporativo` é o repositório centralizado dedicado do GitHub Enterprise (GHE) responsável por:
1. Receber as submissões brutas (`raw/`) anonimizadas dos desenvolvedores participantes do piloto.
2. Servir como base de dados e espaço de trabalho do **Comitê Nimbus Code** para triagem, curadoria e promoção.
3. Armazenar os padrões e regras oficiais homologados (`promoted/`).
4. Executar a rotina automatizada semanal de expurgo de dados brutos com mais de 90 dias (3 meses).

---

## 2. Estrutura de Arquivos e Diretórios

```text
nimbus-code-harness-corporativo/
├── raw/
│   └── <author-hash>/
│       └── <capture-timestamp>-<tool>.yaml
├── promoted/
│   ├── generic/
│   │   ├── workflow/
│   │   │   └── <rule-tag>.yaml
│   │   ├── prompt-engineering/
│   │   │   └── <rule-tag>.yaml
│   │   └── code-conventions/
│   │       └── <rule-tag>.yaml
│   └── bounded-contexts/
│       └── <context-slug>/
│           └── <rule-tag>.yaml
├── archive/
│   ├── purge-audit.jsonl
│   └── .gitkeep
├── manifests/
│   └── index.yaml
├── scripts/
│   ├── triage-cli.py
│   ├── purge-expired.py
│   └── sync-satellite.py
└── .github/
    ├── CODEOWNERS
    └── workflows/
        ├── purge-expired-harness.yml
        └── pr-validation.yml
```

---

## 3. Schemas de Arquivos

### 3.1 Arquivo Bruto: `raw/<author_hash>/<capture_timestamp>-<tool>.yaml`

```yaml
id: "RAW-20260922-f4b2c1d0"
capture_timestamp: "2026-09-22T16:30:00Z"
author_id: "usr_4829fa81"
tool_origin: "claude-code"
source_files:
  - "~/.claude/CLAUDE.md"
sanitization_status: "redacted"
redaction_summary:
  api_keys: 1
  emails: 0
  ips: 2
content_sha256: "9f83c12a76f2... (64 hex)"
status: "pending"
expires_at: "2026-12-21T16:30:00Z"
sanitized_content: |
  # Project Guidelines
  - Always use python 3.11
  - Connect to test server at [REDACTED_IP_ADDRESS] using token [REDACTED_API_KEY]
```

### 3.2 Arquivo Promovido: `promoted/generic/workflow/<rule-tag>.yaml`

```yaml
id: "CORP-HRN-0001"
tag: "claude-subagent-verification-loop"
title: "Loop de Verificação com Subagentes em Tarefas Complexas"
scope: "generic"
target_bounded_context: null
category: "workflow"
target_ide: "claude-code"
raw_source_ref: "RAW-20260922-f4b2c1d0"
promotion_date: "2026-09-23T10:00:00Z"
promoted_by: "leonardo.rodrigues"
approvals:
  - role: "architecture-lead"
    member_id: "leonardo.rodrigues"
    approved_at: "2026-09-23T09:45:00Z"
  - role: "security-guardian"
    member_id: "diego.seguranca"
    approved_at: "2026-09-23T10:00:00Z"
version: 1
status: "active"
rule_content: |
  Quando delegar tarefas para subagentes, sempre execute um subagente independente de revisão
  para auditar o git diff antes de considerar a sessão concluída.
```

---

## 4. Governança e Regras do CODEOWNERS

No arquivo `.github/CODEOWNERS` do repositório central:

```text
# Apenas o Comitê Nimbus Code pode promover ou alterar regras oficiais
/promoted/                  @venha-pra-nuvem/nimbus-code-committee
/manifests/index.yaml       @venha-pra-nuvem/nimbus-code-committee

# Workflows e automações de expurgo
/.github/workflows/         @venha-pra-nuvem/nimbus-code-committee @venha-pra-nuvem/vpndev-arch-board
```

---

## 5. Automação de Expurgo: `.github/workflows/purge-expired-harness.yml`

- **Frequência**: Executado semanalmente aos domingos às 02:00 UTC via `schedule: cron '0 2 * * 0'`.
- **Passos**:
  1. Checkout do repositório com token de automação.
  2. Execução de `python3 scripts/purge-expired.py --retention-days 90`.
  3. Commit e push assinado das exclusões em `raw/` e da atualização em `archive/purge-audit.jsonl`.
