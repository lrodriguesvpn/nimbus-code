# impact-map.md — Feature 006: MultiRepo Support no Spec Kit Template

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `docs/bounded-contexts.yaml` | Criação (novo artefato) | Baixo — arquivo novo, sem risco de regressão | Validar que scripts tolerem arquivo ausente sem falhar |
| `.specify/presets/.../bounded-contexts.yaml` | Atualização do template | Baixo — template, não código executado | Revisão de campos e exemplos antes do merge |
| `.specify/feature.json` | Adição de campos `bounded_contexts` e `repos` (ambos opcionais) | Baixo — campos opcionais não quebram fluxo existente | Validar que `create-new-feature.sh` existente tolera os novos campos |
| `.specify/scripts/bash/create-new-feature.sh` | Adição de flag `--bounded-contexts` e lógica de resolução de repos | Médio — mudança em script crítico do fluxo `speckit-specify` | Flag completamente opcional; sem `--bounded-contexts`, comportamento idêntico ao atual |
| `scripts/setup-github-project.sh` | Adição de passo de vínculo de repos ao Project V2 | Baixo — passo adicional ao final do setup existente; falha isolada não aborta setup |  Testar com e sem `bounded-contexts.yaml` presente |
| `docs/developer-guide.md` | Adição de seção (append) | Baixo — sem remoção de conteúdo existente | Revisão de consistência com seção existente de hierarquia |
| `docs/reuse-catalog.yaml` | Adição de nova entrada | Baixo — append ao catálogo | Nenhum |

---

## 2. Análise de Risco

### R001 — `create-new-feature.sh` quebra para features existentes sem `bounded_contexts` (Médio)

**Cenário**: A flag `--bounded-contexts` é obrigatória e features existentes falham ao
não passá-la.

**Probabilidade**: Baixa — flag desenhada como completamente opcional.

**Impacto**: Fluxo `speckit-specify` quebrado para qualquer feature nova; bloqueio
imediato da equipe.

**Mitigação**: Default de `bounded_contexts` = `[]` e `repos` = `[]`; sem a flag,
o comportamento é byte-a-byte idêntico ao script atual. Testar sem passar a flag
antes de merge.

**Plano de rollback**: Reverter o commit que alterou `create-new-feature.sh`.
Não afeta features já criadas (o `feature.json` já foi gerado).

---

### R002 — `yq` ausente no ambiente do usuário (Médio)

**Cenário**: O script tenta usar `yq` para parsear `bounded-contexts.yaml` e falha
porque `yq` não está instalado no runner ou na máquina do dev.

**Probabilidade**: Média — `yq` não é padrão em runners GitHub Actions nem em macOS sem Homebrew.

**Impacto**: Erro não-intuitivo ao tentar usar `--bounded-contexts`.

**Mitigação**:
1. Tentar `yq` primeiro.
2. Fallback para `python3 -c 'import yaml, sys; ...'` (disponível em macOS 12+ e Ubuntu 20.04+).
3. Se ambos ausentes: parsear com `grep`/`awk` (limitado mas funcional para o schema simples) e imprimir aviso de instalação recomendada.
4. Nunca abortar só por falta de `yq` — degradar graciosamente.

**Plano de rollback**: Instruir o usuário a instalar `yq` (`brew install yq` /
`sudo snap install yq`) ou `python3-yaml`. Nenhuma mudança de código necessária.

---

### R003 — `linkProjectV2ToRepository` não disponível no GHE Server (Baixo)

**Cenário**: O script `setup-github-project.sh` chama a mutation `linkProjectV2ToRepository`
num GHE Server < 3.8 que não suporta essa API.

**Probabilidade**: Baixa — a Nimbus-Code usa GHE Cloud como target principal.

**Impacto**: O passo de vínculo de repos falha com erro GraphQL.

**Mitigação**: Capturar o erro, imprimir mensagem clara com instrução de vínculo manual
via UI (`Project → Settings → Linked Repositories`), e continuar o setup sem abortar.

**Plano de rollback**: Nenhum — o setup restante funciona normalmente; apenas o vínculo
automático de repos precisa ser feito manualmente.

---

### R004 — Slug inválido passado em `--bounded-contexts` (Baixo)

**Cenário**: Dev passa `--bounded-contexts "auth,inexistente"` e o script tenta
resolver um repo para um slug não cadastrado no `bounded-contexts.yaml`.

**Probabilidade**: Média — erro de digitação é comum.

**Impacto**: `feature.json` gerado com repo incorreto; issues criadas no lugar errado.

**Mitigação**: Validar TODOS os slugs contra `bounded-contexts.yaml` ANTES de escrever
qualquer arquivo. Se qualquer slug for inválido, abortar com lista de slugs válidos.

**Plano de rollback**: Deletar o `feature.json` gerado incorretamente (`rm .specify/feature.json`)
e recriar com slugs corretos. A pasta de spec (`specs/NNN-slug/`) permanece válida.

---

## 3. Plano de Rollback Global

Se qualquer parte desta feature causar regressão imediata:

```bash
# Reverter apenas os arquivos alterados desta feature
git revert <commit-hash-desta-feature>
```

Os seguintes arquivos são **seguros de reverter de forma independente**
(sem afetar outros):
- `docs/bounded-contexts.yaml` — novo arquivo, nenhuma dependência existente
- `.specify/presets/.../bounded-contexts.yaml` — template, não executado
- `docs/developer-guide.md` — seção adicionada ao final; reverter não quebra nada

O único arquivo com risco de regressão em fluxo existente é:
- `.specify/scripts/bash/create-new-feature.sh` — testar retrocompatibilidade antes do merge

---

## 4. Go/No-Go Checklist (pré-merge)

- [ ] `create-new-feature.sh` sem `--bounded-contexts` funciona identicamente ao atual
- [ ] `create-new-feature.sh --bounded-contexts "auth,orders"` persiste corretamente em `feature.json`
- [ ] Slug inválido aborta com mensagem clara e lista de válidos
- [ ] `setup-github-project.sh` sem `bounded-contexts.yaml` presente não aborta
- [ ] `setup-github-project.sh` com `bounded-contexts.yaml` exibe confirmação de vínculo
- [ ] Secret scanning passou em todos os arquivos modificados
- [ ] Copilot Code Review solicitado no PR
