# impact-map.md — Feature 020: Governança de Repos Satélite e Intake Greenfield MultiRepo

> Obrigatório para S3/S4. Atualizar se a implementação divergir do plano.

---

## 1. Módulos Impactados

Remediação S3 de 2026-09-20, aprovada para implementação local, **não rollout**:

| Módulo adicional | Risco | Mitigação |
|---|---|---|
| Detector + `validate-bootstrap.yml` | erro/mismatch tratado como sucesso | contrato JSON/exit 0/1/2; script ausente bloqueia |
| Scanner + `satellite-preset-audit.yml` + report helper | erro de API classificado como não instalado; contagem zero falha | CSV validado, estado error, falha operacional propagada |
| `auto-sync-preset.yml` + sync helper | mutação cross-repo não autorizada | opt-in desligado, dispatch manual, mesma org, credencial App/PAT existente; sem GITHUB_TOKEN cross-repo |
| Bootstrap refresh gerenciado (ownership coordenador) | provisionamento ou commit indevido | executar bundle com --refresh-preset/--local no satélite; verificar versão antes de escrita remota |
| Testes de governança locais | falsa evidência de rollout | mocks sem rede; gates #433/#445 explicitamente abertos |

Rollback: desabilitar `NIMBUS_SATELLITE_SYNC_ENABLED`, revisar/reverter PR quando
necessário. Não apagar branches nem forçar histórico. Habilitação/remoção da
flag depende de evidência e aprovação humana no [plan](./plan.md).

| Módulo | Tipo de impacto | Risco | Mitigação |
|---|---|---|---|
| `bootstrap.sh` | Extensão do fluxo de intake, registro da decisão de topologia e handoff para multirepo | Médio — bootstrap é ponto crítico de entrada | Introduzir comportamento adicional só no ramo greenfield; validar prompts não interativos e manter bugfixes fora desta feature |
| `docs/developer-guide.md` | Ampliação do manual operacional | Baixo | Revisão de consistência com a seção MultiRepo existente |
| `docs/bounded-contexts.yaml` | Reforço normativo do papel de repo central/satélite | Baixo | Limitar a mudança à governança, sem alterar slugs existentes |
| `README.md` | Atualização do onboarding | Baixo | Ajustar somente as seções relacionadas a greenfield/multirepo |
| `templates/BROWNFIELD-SETUP-CHECKLIST.md` | Alinhamento do fluxo brownfield | Baixo | Garantir que a feature não reescreva o checklist como se fosse greenfield |
| `templates/workflows/update-speckit-and-bundle.yml` | Referência operacional de alinhamento satélite | Baixo | Reaproveitar o workflow existente em vez de criar outro mecanismo |

---

## 2. Análise de Risco

### R001 — Repo quase vazio classificado como brownfield (Médio)

**Cenário**: repositório contendo apenas README/licença/setup mínimo entra no
fluxo brownfield por uma heurística simplista.

**Probabilidade**: Média.

**Impacto**: o projeto perde a experiência correta de greenfield logo na
largada e deixa de registrar a decisão estrutural.

**Mitigação**:
1. Definir “código de aplicação relevante” explicitamente na documentação e no contrato.
2. Validar quickstart com exemplos de repositório quase vazio.
3. Preservar explicação textual da classificação no bootstrap.

**Plano de rollback**: reverter a lógica de classificação introduzida e voltar
ao comportamento anterior até refinar a heurística.

---

### R002 — Baseline de domínios interpretada como obrigatória (Médio)

**Cenário**: times passam a tratar FRONT/BACK/DESIGN/DATA/JOBS como taxonomia
fixa, mesmo quando o produto exige recortes diferentes.

**Probabilidade**: Média.

**Impacto**: satélites artificiais, overhead de repositórios e modelagem ruim de ownership.

**Mitigação**:
1. Documentar baseline explicitamente como recomendação.
2. Exigir justificativa apenas para adaptação, não aprovação extraordinária.
3. Reforçar o papel da primeira spec estrutural como momento de ajuste.

**Plano de rollback**: suavizar ou remover a baseline nas docs se a revisão
humana concluir que o guidance ficou prescritivo demais.

---

### R003 — Satélite volta a armazenar specs localmente (Médio)

**Cenário**: apesar da política central, times criam `specs/` nos satélites por conveniência.

**Probabilidade**: Média.

**Impacto**: drift de processo, dupla fonte de verdade e perda de rastreabilidade.

**Mitigação**:
1. Tornar a regra explícita em docs, contrato e quickstart.
2. Planejar tasks futuras de enforcement/guard se a recorrência persistir.
3. Diferenciar claramente repo central (governança) de satélite (execução).

**Plano de rollback**: se a política estiver inviável operacionalmente, reavaliar
o modelo em nova spec — nunca flexibilizar silenciosamente nesta feature.

---

### R004 — Bundle central e satélites divergem por atualização manual ad hoc (Médio)

**Cenário**: times atualizam satélites “na mão” fora do fluxo oficial.

**Probabilidade**: Média.

**Impacto**: comportamento inconsistente entre produtos e perda de previsibilidade do bootstrap.

**Mitigação**:
1. Reaproveitar o workflow oficial de update como mecanismo central.
2. Exigir PR revisado como caminho padrão.
3. Documentar que não existe atalho oficial alternativo para sync.

**Plano de rollback**: se a integração com o workflow oficial gerar ruído,
reverter apenas a parte documental nova e replanejar a governança de sync.

---

## 3. Plano de Rollback Global

Se a feature introduzir orientação errada de onboarding:

```bash
git revert <commit-hash-da-feature>
```

Arquivos seguros para reversão parcial:
- `docs/developer-guide.md`
- `README.md`
- `templates/BROWNFIELD-SETUP-CHECKLIST.md`
- `docs/bounded-contexts.yaml`

Arquivo que exige mais cuidado na reversão:
- `bootstrap.sh` — por ser ponto crítico do onboarding e conviver com bugfixes paralelos

---

## 4. Critérios de Go / No-Go

### Go

- O fluxo diferencia corretamente greenfield de brownfield em linguagem compreensível
- A decisão mono vs multirepo fica registrada com motivo
- A baseline de domínios é claramente sugerida, não imposta
- A regra “spec só no repo central” fica inequívoca
- O alinhamento satélite → bundle oficial continua baseado em PR revisado

### No-Go

- O bootstrap continua ambíguo sobre greenfield vs brownfield
- A decisão mono vs multirepo pode ser pulada sem justificativa
- A documentação deixa margem para specs locais em satélites como prática normal
- O plano introduz mecanismo paralelo de sync em vez de reaproveitar o oficial
