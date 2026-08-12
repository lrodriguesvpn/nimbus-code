# Data Model — Platform Preset CMDB + Security/Compliance DSC

## Overview

Este modelo cobre descoberta multi-cloud, consolidacao CMDB orientada a IA,
comparacao de baseline e geracao de perfil DSC versionado.

---

## 1) PlatformExecution

Representa uma execucao fim a fim de coleta/governanca.

### Attributes
- `executionId` (string, required, unique)
- `requestedBy` (string, required)
- `authContextId` (string, required)
- `targetPlatforms` (array, required: azure/aws/gcp)
- `tenantScope` (object, required)
- `startedAt` (datetime, required)
- `finishedAt` (datetime, optional)
- `status` (enum: pending/running/partial/succeeded/failed, required)
- `advisoryMode` (boolean, required, default true)

### Validation rules
- `targetPlatforms` nao pode ser vazio.
- execucao sem `authContextId` valido deve falhar antes da coleta.

---

## 2) CloudAsset

Ativo descoberto em qualquer provedor.

### Attributes
- `assetId` (string, required, unique in provider scope)
- `provider` (enum: azure/aws/gcp, required)
- `accountOrSubscription` (string, required)
- `region` (string, optional)
- `assetType` (string, required)
- `displayName` (string, required)
- `tags` (map<string,string>, optional)
- `securityCriticality` (enum: low/medium/high/critical, required)
- `discoveredAt` (datetime, required)
- `sourceExecutionId` (string, required)

### Relationships
- many-to-one com `PlatformExecution`.
- one-to-many com `AssetRelationship`.

---

## 3) AssetRelationship

Relacao entre ativos (dependencia, exposicao, ownership etc.).

### Attributes
- `relationshipId` (string, required, unique)
- `fromAssetId` (string, required)
- `toAssetId` (string, required)
- `relationshipType` (string, required)
- `confidenceScore` (number 0..1, required)
- `observedAt` (datetime, required)

### Validation rules
- proibido auto-relacionamento (`fromAssetId == toAssetId`) salvo tipo `self-metadata`.

---

## 4) CmdbRecord

Registro consolidado para consumo por IA e validacoes.

### Attributes
- `cmdbRecordId` (string, required, unique)
- `canonicalAssetRef` (string, required)
- `providerFragments` (array<object>, required)
- `evidenceRefs` (array<string>, required)
- `lastConsolidatedAt` (datetime, required)
- `dataQualityScore` (number 0..1, required)
- `state` (enum: active/deprecated/suppressed, required)

### Validation rules
- `lastConsolidatedAt` deve ser no maximo 24h atras para estado de conformidade plena.

---

## 5) PolicyBaseline

Baseline corporativo de seguranca/compliance por dominio.

### Attributes
- `baselineId` (string, required, unique)
- `domain` (string, required)
- `controlId` (string, required)
- `expectedState` (object, required)
- `severity` (enum: low/medium/high/critical, required)
- `version` (string, required)
- `effectiveFrom` (date, required)
- `effectiveTo` (date, optional)

### Validation rules
- nao pode haver dois controles ativos com mesmo `domain + controlId + version`.

---

## 6) AppliedPolicyState

Estado observado de politica/configuracao no ambiente.

### Attributes
- `appliedStateId` (string, required, unique)
- `domain` (string, required)
- `controlId` (string, required)
- `observedState` (object, required)
- `observedAt` (datetime, required)
- `sourceAssetRefs` (array<string>, required)
- `sourceExecutionId` (string, required)

---

## 7) ComplianceFinding

Resultado da comparacao baseline vs estado aplicado.

### Attributes
- `findingId` (string, required, unique)
- `baselineId` (string, required)
- `appliedStateId` (string, required)
- `result` (enum: compliant/non-compliant/not-applicable, required)
- `impact` (enum: low/medium/high/critical, required)
- `recommendation` (string, required)
- `exceptionTicket` (string, optional)
- `createdAt` (datetime, required)

---

## 8) CustomizationException

Customizacao fora do baseline com justificativa e aprovacao.

### Attributes
- `exceptionId` (string, required, unique)
- `domain` (string, required)
- `controlId` (string, required)
- `reason` (string, required)
- `approvedBy` (string, required)
- `expiresAt` (datetime, optional)
- `riskAcceptanceLevel` (enum: low/medium/high/critical, required)
- `status` (enum: pending/approved/rejected/expired, required)

---

## 9) DscProfile

Modelo de estado desejado versionado.

### Attributes
- `dscProfileId` (string, required, unique)
- `version` (string, required)
- `scope` (object, required)
- `desiredControls` (array<object>, required)
- `derivedFromExecutionId` (string, required)
- `generatedAt` (datetime, required)
- `previousVersion` (string, optional)
- `deltaSummary` (string, required)

### Validation rules
- versao deve ser monotonicamente crescente por escopo.
- `generatedAt` de uma nova versao deve ser posterior a versao anterior.

---

## State transitions

### PlatformExecution
- `pending -> running -> succeeded`
- `running -> partial`
- `running -> failed`

### CmdbRecord
- `active -> deprecated`
- `active -> suppressed`
- `suppressed -> active`

### CustomizationException
- `pending -> approved|rejected`
- `approved -> expired`

---

## Volume and scale assumptions

- ate 1M ativos consolidados no primeiro ciclo completo multi-cloud;
- ate 10M relacionamentos entre ativos;
- atualizacao completa a cada 24h por ambiente;
- queries de governanca devem suportar uso concorrente de times de plataforma,
  seguranca e compliance.
