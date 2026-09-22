# Contrato do Motor de Anonimização e Sanitização: `harness_anonymizer.py`

**Feature**: `029-harness-corporativo-ide`  
**Módulo**: `scripts/lib/harness_anonymizer.py`  
**Versão**: 1.0.0

---

## 1. Responsabilidade

O módulo `harness_anonymizer.py` é responsável por receber o conteúdo de texto livre do Harness Agêntico IDE pessoal e executar a varredura determinística e substituição de qualquer segredo, token, chave de API, credencial, PII (identificadores pessoais) e informações de rede/clientes, garantindo um comportamento estritamente **Fail-Closed**.

---

## 2. Interface CLI do Módulo

O script pode ser executado diretamente via terminal ou invocado como módulo Python:

```bash
python3 scripts/lib/harness_anonymizer.py --input <arquivo> [--output <arquivo>] [--strict]
```

### Argumentos CLI

- `--input <path>` (obrigatório): Caminho do arquivo a ser lido (ou `-` para STDIN).
- `--output <path>` (opcional): Caminho onde o arquivo sanitizado será gravado. Se omitido, emite o resultado em STDOUT.
- `--report <path>` (opcional): Caminho para exportar um resumo JSON de auditoria da sanitização (`AnonymizationReport`).
- `--strict` (padrão: ativado): Se qualquer padrão de alta entropia residual ou segredo não redigido persistir, encerra imediatamente com status `1` (bloqueio).

---

## 3. Padrões de Detecção e Redação

| Categoria | Padrão Regex / Heurística | Token de Substituição |
|---|---|---|
| **Chave OpenAI** | `sk-[a-zA-Z0-9]{20,T}` | `[REDACTED_OPENAI_KEY]` |
| **Chave Anthropic** | `sk-ant-[a-zA-Z0-9_\-]{20,}` | `[REDACTED_ANTHROPIC_KEY]` |
| **AWS Access Key** | `(?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])` (iniciando com AKIA, ASIA, etc.) | `[REDACTED_AWS_KEY]` |
| **GitHub Token** | `gh[pousr]_[A-Za-z0-9_]{36,255}` | `[REDACTED_GITHUB_TOKEN]` |
| **Chave Privada** | `-----BEGIN [A-Z ]+ PRIVATE KEY-----[\s\S]*?-----END [A-Z ]+ PRIVATE KEY-----` | `[REDACTED_PRIVATE_KEY_BLOCK]` |
| **Bearer Token / JWT** | `ey[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*` | `[REDACTED_JWT_TOKEN]` |
| **E-mail** | `[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+` | `[REDACTED_EMAIL]` |
| **CPF** | `\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b` | `[REDACTED_CPF]` |
| **IP (IPv4)** | `\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b` | `[REDACTED_IP_ADDRESS]` |
| **Senha / Secret** | `(?i)(password|secret|pwd|apikey|api_key)\s*[:=]\s*['"][^'"]+['"]` | `\1: "[REDACTED_SECRET]"` |

---

## 4. Algoritmo de Entropia de Shannon

Para mitigar credenciais aleatórias que não correspondam a prefixos conhecidos, o analisador divide palavras alfanuméricas com tamanho maior que 16 caracteres e calcula a entropia de Shannon:

$$H(X) = -\sum_{i=1}^{n} P(x_i) \log_2 P(x_i)$$

Se $H(X) \ge 4.2$ e a string não for um identificador de caminho conhecido ou hash de commit do git:
- O token é redigido como `[REDACTED_HIGH_ENTROPY_STRING]`.
- Se a flag `--strict` estiver ativa e o contexto indicar atribuição de segredo, o módulo encerra com código de erro 1.

---

## 5. Schema do Relatório de Auditoria (`AnonymizationReport`)

Formato emitido via `--report`:

```json
{
  "timestamp": "2026-09-22T16:30:00Z",
  "source_file": "/Users/dev/.claude/CLAUDE.md",
  "input_size_bytes": 4512,
  "output_size_bytes": 4120,
  "input_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "output_sha256": "8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4",
  "redactions_count": {
    "api_keys": 2,
    "emails": 1,
    "ip_addresses": 3,
    "passwords": 0,
    "high_entropy_tokens": 1
  },
  "verdict": "PASSED"
}
```

---

## 6. Comportamento em Caso de Falha (Fail-Closed)

Se o analisador encontrar um padrão suspeito que viole a checagem pós-sanitização:
1. Imprime em `stderr`: `[ERRO DE SEGURANÇA]: Detecção residual de credencial suspeita na linha N. Execução abortada preventivamente.`
2. Nenhum arquivo de saída é escrito em `--output`.
3. Retorna código de saída `1`.
