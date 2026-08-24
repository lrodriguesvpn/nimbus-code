# Data Model: Governança de Repos Satélite e Intake Greenfield MultiRepo

## Entities

### BootstrapContext

Representa o contexto inicial observado pelo bootstrap antes de orientar o fluxo.

**Fields**
- `repository_reference`: repositório onde o bootstrap está sendo executado
- `has_relevant_application_code`: boolean
- `relevant_code_indicators`: lista de diretórios, arquivos ou manifests que justificaram a classificação
- `ignored_non_application_artifacts`: lista de artefatos encontrados que não contam sozinhos como código relevante
- `detected_mode`: `greenfield` ou `brownfield`
- `detection_rationale`: explicação legível da classificação

### TopologyDecision

Representa a decisão estrutural do produto durante o fluxo greenfield.

**Fields**
- `delivery_model`: `monorepo` ou `multirepo`
- `decision_reason`: justificativa explícita para a escolha, incluindo motivo principal e trade-off esperado
- `decision_owner`: papel ou responsável que confirmou a escolha
- `recorded_in_feature`: referência da feature onde a decisão ficou registrada

### SatelliteDomainProposal

Representa a proposta inicial de domínios para satélites em um produto multirepo.

**Fields**
- `domain_name`: nome do domínio satélite
- `proposal_type`: `baseline` ou `custom`
- `justification`: motivo para manter, remover, renomear ou adicionar o domínio
- `ownership`: time, papel ou repositório responsável pelo domínio

### RepositoryRole

Representa o papel de um repositório no ecossistema do produto.

**Fields**
- `repository_name`
- `role`: `central` (repo central) ou `satellite` (repo satélite)
- `stores_specs`: boolean
- `stores_code`: boolean
- `receives_routed_tasks`: boolean

### SyncGovernanceRule

Representa a regra operacional de alinhamento entre repo central e satélites.

**Fields**
- `update_source`: bundle oficial do repo central
- `update_target`: repo satélite bootstrapado
- `update_path`: workflow oficial + PR revisado
- `direct_main_update_allowed`: boolean (sempre `false`)

## Relationships

- Um `BootstrapContext` leva a exatamente uma `TopologyDecision` quando o modo detectado é `greenfield`
- Uma `TopologyDecision` do tipo `multirepo` gera uma ou mais `SatelliteDomainProposal`
- Um `RepositoryRole` do tipo `central` (repo central) referencia vários `RepositoryRole` do tipo `satellite` (repo satélite)
- Toda `SatelliteDomainProposal` depende de uma `SyncGovernanceRule` para permanecer alinhada ao bundle oficial

## Validation Rules

- `has_relevant_application_code = false` implica orientação inicial greenfield
- `has_relevant_application_code = true` implica orientação inicial brownfield
- `relevant_code_indicators` deve permanecer vazio quando apenas README, licença, setup mínimo, workflows ou templates estiverem presentes
- `delivery_model` não pode ser definido sem `decision_reason`
- `decision_reason` deve registrar motivo principal e trade-off esperado em texto legível por humanos
- Produtos `multirepo` devem ter pelo menos uma `SatelliteDomainProposal`
- Toda `SatelliteDomainProposal` do tipo `custom` deve informar `justification` e `ownership`
- Repositórios com `role = central` (repo central) devem ter `stores_specs = true`
- Repositórios com `role = satellite` (repo satélite) devem ter `stores_specs = false` como padrão operacional
- `direct_main_update_allowed` deve permanecer `false`
