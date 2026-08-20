# Contract: Devcontainer Reference

**Arquivo**: `.devcontainer/devcontainer.json`

## Schema esperado (resumo)

```json
{
  "name": "Nimbus-Code Standard Devcontainer",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {},
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": ["GitHub.copilot", "eamodio.gitlens"]
    }
  },
  "postCreateCommand": "bash scripts/setup-dev-environment.sh"
}
```

## Regra de validação (AC-1)

Ao abrir um Codespace com este devcontainer, o `postCreateCommand` deve
completar sem erro e deixar `python3`, `node`, `gh`, `bash` disponíveis no PATH
— sem nenhum passo manual adicional do desenvolvedor.
