# Quickstart: Codespaces para DEV e CI/CD

**Purpose**: Validação E2E do devcontainer de referência e da política de
governança propostos por este plano.

## Cenário 1 — Devcontainer zero-setup (AC-1)

```sh
gh codespace create --repo <org>/nimbus-code --devcontainer-path .devcontainer/devcontainer.json
gh codespace ssh
python3 --version && node --version && gh --version
```

**Validação**: todos os comandos retornam versão válida, sem nenhum passo
manual de instalação.

## Cenário 2 — Validação antecipada de pipeline (AC-2)

```sh
# Dentro do Codespace:
bash scripts/setup-github-labels.sh --dry-run
```

**Validação**: resultado equivalente ao que o CI produziria para a mesma
mudança, documentado em `docs/ci-cd-acceleration-map.md`.

## Cenário 3 — Governança de Codespace ocioso (AC-3)

```sh
gh codespace list
# Deixar um Codespace de teste ocioso além do limite configurado
```

**Validação**: Codespace é parado automaticamente (pela configuração nativa do
GitHub ou pelo workflow de referência), sem intervenção manual.

## Cenário 4 — Paridade de segurança para sessão de agente (AC-4)

Revisar `docs/codespaces-adoption-guide.md`, seção de modelo de segurança para
agentes, e confirmar que o escopo de segredos permitido é explicitamente igual
ao já exigido para CI/CD do mesmo repositório — sem ambiguidade.

## Checklist final

- [ ] AC-1 validado (Cenário 1)
- [ ] AC-2 validado (Cenário 2)
- [ ] AC-3 validado (Cenário 3)
- [ ] AC-4 validado (Cenário 4)
