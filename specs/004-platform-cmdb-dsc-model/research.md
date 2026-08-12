# Phase 0 Research — Platform Preset CMDB + Baselines

## Decision 1: MVP scope covers multi-cloud

- **Decision**: incluir Azure, AWS e GCP no MVP.
- **Rationale**: alinhado ao direcionamento da feature para governanca de plataforma corporativa ampla.
- **Alternatives considered**:
  - somente Microsoft (mais simples, menor cobertura);
  - Microsoft + conectores futuros (adiaria requisito explicito de multicloud).

## Decision 2: Security/compliance coverage is full tenant domain set

- **Decision**: mapear todos os dominios de seguranca/compliance disponiveis no tenant avaliado.
- **Rationale**: evita lacunas de conformidade e reduz risco de auditoria parcial.
- **Alternatives considered**:
  - somente identidade e acesso;
  - subconjunto critico inicial.

## Decision 3: Authentication must use central corporate SSO

- **Decision**: adotar SSO corporativo unico para todas as operacoes da plataforma.
- **Rationale**: atende controle nao-negociavel da constituicao e unifica trilha de auditoria.
- **Alternatives considered**:
  - login por provedor cloud (fragmenta governanca);
  - modelo hibrido com contas locais (aumenta superficie de risco).

## Decision 4: Terraform validation mode in MVP is advisory

- **Decision**: validacao baseada no CMDB em modo advisory no MVP, com relatorio e trilha obrigatoria de excecao.
- **Rationale**: habilita adocao sem bloqueio imediato de pipelines legados.
- **Alternatives considered**:
  - bloqueio imediato para nao conformidade critica;
  - modo hibrido bloqueante para parte dos achados.

## Decision 5: CMDB/DSC full refresh cadence is 24h

- **Decision**: executar atualizacao completa em no maximo 24 horas por ambiente no escopo.
- **Rationale**: equilibrio entre custo operacional multicloud e frescor suficiente para governanca.
- **Alternatives considered**:
  - 1h (alto custo operacional inicial);
  - 7 dias (frescor insuficiente para controles de compliance).
