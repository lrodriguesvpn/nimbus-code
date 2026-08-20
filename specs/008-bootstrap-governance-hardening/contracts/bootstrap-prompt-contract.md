# Contract: Bootstrap Prompt

**Componente**: `bootstrap.sh`

## Comportamento interativo (padrão)

Ao rodar sem flags, `bootstrap.sh` deve perguntar, nesta ordem, antes de instalar
qualquer preset:

```text
? Este repositório é de Plataforma/Cliente (ambientes, contas cloud, tenants) ou
  de Dev Standards (projeto/produto de código)? [platform/dev_standards]
```

- Resposta `platform` → instala `nimbus-code-platform-standards`
- Resposta `dev_standards` → instala `nimbus-code-standards`
- Qualquer outra entrada → repete a pergunta (não assume padrão)

## Comportamento não-interativo (CI / automação)

Para permitir uso em pipelines, aceitar a flag `--repo-type`:

```sh
./bootstrap.sh --repo-type dev_standards
./bootstrap.sh --repo-type platform
```

- Flag ausente + terminal não-interativo (`! [ -t 0 ]`) → falha explícita com
  mensagem indicando que `--repo-type` é obrigatório em modo não-interativo
  (nunca assume um padrão silenciosamente — FR-001, FR-009)

## Saída esperada

Ao final, o script deve imprimir de forma inequívoca qual preset foi instalado:

```text
✅ Preset instalado: nimbus-code-standards (tipo de repositório: dev_standards)
```
