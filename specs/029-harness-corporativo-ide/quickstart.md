# Quickstart: Harness Corporativo — Consolidação de Harness Agêntico IDE Pessoal

**Feature**: `029-harness-corporativo-ide`  
**Data**: 2026-09-22  
**Agente**: NC-Arch (Nimbus Solution Architect)

Este guia prático fornece o passo a passo executável para testar e validar o ciclo de vida completo do Harness Corporativo, cobrindo captura, sanitização, triagem, expurgo e redistribuição idempotente.

---

## Pré-requisitos

1. Python 3.11+ instalado localmente.
2. Repositório template atualizado (`nimbus-code`).
3. Repositório central clonado localmente para os testes (ex.: `../nimbus-code-harness-corporativo`).
4. Variáveis de ambiente configuradas para chamadas ao Gateway (apenas nos cenários com LLM).

---

## Cenário 1 — Inspeção Visual Local da Anonimização (`--anonymize-only`)

Valida que o desenvolvedor pode verificar exatamente o que será anonimizado antes de qualquer transmissão externa (AC-1, AC-3).

```bash
# 1. Cria um arquivo de teste simulando ~/.claude/CLAUDE.md com um token fictício e e-mail
mkdir -p /tmp/test-harness
cat << 'EOF' > /tmp/test-harness/CLAUDE.md
# Instruções do Meu Projeto
- Sempre rodar testes com pytest
- Contato do dev: fulano.silva@empresa.com.br
- Chave temporária de teste: sk-ant-api03-abcdef12345678901234567890
- IP do ambiente de homologação: 10.120.45.67
EOF

# 2. Executa a anonimização sem transmitir nada
scripts/harvest-patterns.sh \
  --source ide-harness \
  --harness-path /tmp/test-harness/CLAUDE.md \
  --anonymize-only
```

**Resultado Esperado**:
- Exibição do texto sanitizado no terminal.
- `fulano.silva@empresa.com.br` substituído por `[REDACTED_EMAIL]`.
- Chave `sk-ant-...` substituída por `[REDACTED_ANTHROPIC_KEY]`.
- IP `10.120.45.67` substituído por `[REDACTED_IP_ADDRESS]`.
- Código de saída `0`.

---

## Cenário 2 — Bloqueio Fail-Closed com Segredo Residual (AC-3, FR-005)

Comprova que o sistema aborta a operação caso detecte um segredo de alta entropia que viole a checagem rigorosa de segurança.

```bash
# 1. Cria um arquivo com chave privada RSA não permitida
cat << 'EOF' > /tmp/test-harness/bad-secret.md
# Configurações com credencial exposta
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0Y3e8+... (chave privada crua)
-----END RSA PRIVATE KEY-----
EOF

# 2. Tenta rodar a extração
scripts/harvest-patterns.sh \
  --source ide-harness \
  --harness-path /tmp/test-harness/bad-secret.md \
  --dry-run
```

**Resultado Esperado**:
- O script aborta imediatamente com erro explícito em `stderr`:
  `[FAIL-CLOSED]: Bloqueio preventivo. Credencial crítica detectada na linha 2. Abortando sem enviar ao LLM.`
- Código de saída `1`.
- Nenhuma chamada HTTP é disparada.

---

## Cenário 3 — Captura Oficial On-Demand no Repositório Central (AC-1, AC-2)

Executa a captura oficial e garante que a escrita ocorre exclusivamente no repositório central dedicado.

```bash
export HARVEST_API_URL="https://gateway.nuvem.corp/api/harvest"
export HARVEST_API_TOKEN="token_m2m_teste"
export HARVEST_CENTRAL_REPO_DIR="/tmp/central-repo-mock"

# Inicializa o repositório central mock
mkdir -p "$HARVEST_CENTRAL_REPO_DIR"/raw

# Executa a captura
scripts/harvest-patterns.sh \
  --source ide-harness \
  --harness-path /tmp/test-harness/CLAUDE.md

# Verifica onde o arquivo foi gravado
ls -la "$HARVEST_CENTRAL_REPO_DIR"/raw/*/*.yaml
```

**Resultado Esperado**:
- Arquivo YAML gerado em `$HARVEST_CENTRAL_REPO_DIR/raw/<author_hash>/...`.
- O arquivo local `docs/reuse-catalog.yaml` permanece 100% inalterado (`git status docs/reuse-catalog.yaml` limpo).
- Código de saída `0`.

---

## Cenário 4 — Triagem e Promoção Manual pelo Comitê Nimbus Code (AC-4, FR-006)

Simula a curadoria humana pelo Comitê.

```bash
# Executa ferramenta de triagem do Comitê no repositório central
python3 scripts/triage-cli.py \
  --repo-dir "$HARVEST_CENTRAL_REPO_DIR" \
  --action promote \
  --raw-id "RAW-20260922-f4b2c1d0" \
  --tag "pytest-isolation-rule" \
  --category "code-conventions" \
  --scope "generic" \
  --approver-role "architecture-lead" \
  --approver-id "leonardo.rodrigues" \
  --second-approver-role "security-guardian" \
  --second-approver-id "diego.seguranca"
```

**Resultado Esperado**:
- Arquivo criado em `$HARVEST_CENTRAL_REPO_DIR/promoted/generic/code-conventions/pytest-isolation-rule.yaml`.
- Status em `raw/...` atualizado para `promoted`.
- Registro de decisão formal gerado com quórum válido de 2 membros.

---

## Cenário 5 — Expurgo Automático de Itens Brutos com Mais de 90 Dias (AC-5, FR-008)

Valida o cumprimento da diretriz de expurgo LGPD.

```bash
# 1. Cria um item fictício com data de captura há 95 dias atrás
mkdir -p "$HARVEST_CENTRAL_REPO_DIR"/raw/old_user
cat << 'EOF' > "$HARVEST_CENTRAL_REPO_DIR"/raw/old_user/expired.yaml
id: "RAW-20260501-11223344"
capture_timestamp: "2026-05-01T12:00:00Z"
status: "pending"
expires_at: "2026-07-30T12:00:00Z"
sanitized_content: "Old unused rules"
EOF

# 2. Executa a rotina de expurgo
python3 scripts/purge-expired.py \
  --repo-dir "$HARVEST_CENTRAL_REPO_DIR" \
  --retention-days 90

# 3. Verifica remoção do arquivo e presença do log de auditoria
test ! -f "$HARVEST_CENTRAL_REPO_DIR"/raw/old_user/expired.yaml
cat "$HARVEST_CENTRAL_REPO_DIR"/archive/purge-audit.jsonl
```

**Resultado Esperado**:
- O arquivo expirado `expired.yaml` é fisicamente excluído.
- Linha de log correspondente presente em `archive/purge-audit.jsonl` com hash e timestamp do expurgo.

---

## Cenário 6 — Redistribuição Idempotente para Repositório Satélite (AC-6, FR-009)

Valida que regras específicas de bounded context são sincronizadas sem sobrescrever arquivos locais existentes.

```bash
# Cria um repositório satélite de teste com regras existentes
mkdir -p /tmp/satellite-repo/.claude
cat << 'EOF' > /tmp/satellite-repo/.claude/CLAUDE.md
# Customização Pessoal do Desenvolvedor Local
- Meu atalho especial: bash test.sh
EOF

# Dispara a redistribuição da regra corporativa para o satélite
scripts/sync-corporate-harness.sh \
  --source-rule "$HARVEST_CENTRAL_REPO_DIR/promoted/bounded-contexts/pagamentos/pix-idempotency.yaml" \
  --target-repo /tmp/satellite-repo

# Confirma que a customização original foi mantida
grep "Meu atalho especial" /tmp/satellite-repo/.claude/CLAUDE.md
```

**Resultado Esperado**:
- A customização do desenvolvedor local é preservada intacta.
- A regra corporativa é adicionada sob bloco gerenciado ou mantida em arquivo `.divergent` caso haja conflito irresolúvel.
