# Contrato de Interface: CLI Harvester Estendido (`scripts/harvest-patterns.sh`)

**Feature**: `029-harness-corporativo-ide`  
**Módulo**: `scripts/harvest-patterns.sh`  
**Versão da Interface**: 2.0.0

---

## 1. Descrição

O script `scripts/harvest-patterns.sh` é estendido para aceitar o modo `--source ide-harness`. A invocação é sempre manual e on-demand por parte de um desenvolvedor humano.

---

## 2. Assinatura e Argumentos

```bash
scripts/harvest-patterns.sh [OPÇÕES]
```

### Argumentos de Linha de Comando

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|---|---|---|---|---|
| `--source` | string (`code` \| `ide-harness`) | Não | `code` | Define a fonte de extração: metadados estruturais de código (`code`) ou arquivos de Harness Agêntico IDE (`ide-harness`). |
| `--harness-path` | string (caminho) | Não | Vazio | Caminho explícito para um arquivo ou diretório de regras (ex.: `~/.claude/CLAUDE.md`, `.cursor/rules`). Se omitido no modo `ide-harness`, realiza autodescoberta de ambos os caminhos padrão. |
| `--target-central-repo` | string (caminho) | Condicional | `$HARVEST_CENTRAL_REPO_DIR` | Caminho local para o clone do repositório central dedicado `nimbus-code-harness-corporativo`. **Obrigatório** quando `--source ide-harness` está ativo e `--dry-run` não foi informado. |
| `--dry-run` | flag booleana | Não | `false` | Executa a descoberta e a anonimização local, exibindo o payload sanitizado e as entidades detectadas sem gravar em disco nem realizar chamada HTTP externa. |
| `--anonymize-only` | flag booleana | Não | `false` | Executa exclusivamente a sanitização local de `harness_anonymizer.py` e imprime o resultado na saída padrão para conferência visual prévia do colaborador. |
| `--output` | string (caminho) | Não | Vazio | **Proibido** quando `--source ide-harness` está ativo (dispara erro se apontar para `docs/reuse-catalog.yaml` ou qualquer arquivo fora do repositório central). |

---

## 3. Variáveis de Ambiente

| Variável | Obrigatória | Descrição |
|---|---|---|
| `HARVEST_API_URL` | Sim (exceto com `--dry-run` ou `--anonymize-only`) | URL do endpoint HTTP do Gateway de IA (ex.: `https://gateway.nuvem.corp/api/harvest`). |
| `HARVEST_API_TOKEN` | Sim (exceto com `--dry-run` ou `--anonymize-only`) | Bearer token de autenticação machine-to-machine. |
| `HARVEST_CENTRAL_REPO_DIR` | Sim (se `--target-central-repo` omitido e não for `--dry-run`) | Caminho do repositório central GHE onde o arquivo bruto deve ser gravado. |

---

## 4. Códigos de Saída (Exit Codes)

| Código | Significado | Condição |
|---|---|---|
| `0` | Sucesso | Extração e gravação realizadas, ou nada capturado em caso de harness vazio. |
| `1` | Erro de Sanitização (Fail-Closed) | `harness_anonymizer.py` detectou segredo não-redigível, alta entropia residual ou falha de sintaxe. |
| `2` | Erro de Argumentos / Roteamento Inválido | Tentativa de gravar no repositório de trabalho local em vez do repositório central, ou falta de variáveis obrigatórias. |
| `3` | Falha de Comunicação HTTP | `HARVEST_API_URL` retornou status diferente de 200 ou timeout na requisição. |
| `4` | Falha de Escrita no Repositório Central | Diretório do repositório central não existe, sem permissão ou caminho inválido. |

---

## 5. Exemplos de Uso

### 5.1 Conferência visual rápida de sanitização (modo seguro)
```bash
scripts/harvest-patterns.sh --source ide-harness --anonymize-only
```

### 5.2 Simulação completa com visualização de candidatos
```bash
scripts/harvest-patterns.sh --source ide-harness --dry-run
```

### 5.3 Execução oficial gravando no repositório central
```bash
export HARVEST_API_URL="https://gateway.nuvem.corp/api/harvest"
export HARVEST_API_TOKEN="sec_token_abc123"
export HARVEST_CENTRAL_REPO_DIR="../nimbus-code-harness-corporativo"

scripts/harvest-patterns.sh --source ide-harness
```
