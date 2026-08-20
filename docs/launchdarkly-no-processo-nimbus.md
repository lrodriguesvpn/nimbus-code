# LaunchDarkly no processo Nimbus-Code

## Objetivo

Descrever como adotar LaunchDarkly como provider de feature flags sem mudar o
modelo atual de governança do Nimbus-Code.

## Princípio

- **Nimbus-Code define o processo** (governança, gates, rollback, cleanup).
- **LaunchDarkly operacionaliza a flag** (segmentação, rollout progressivo,
  kill switch, auditoria).

## Fluxo de implantação

1. **Modelar a flag no `plan.md`**
   - Nome da flag, owner, tipo (`release`/`ops`/`experiment`), ambientes,
     default por ambiente (recomendado OFF em frentes concorrentes), critérios
     de ativação/rollback e condição de remoção.

2. **Provisionar no LaunchDarkly**
   - Criar projeto e ambientes (`dev`, `hml`, `prod`).
   - Criar segmentos (`interno`, `cliente-piloto`, `canary`).
   - Criar flag com regras por ambiente/segmento.

3. **Integrar no código**
   - Aplicar OpenFeature SDK (camada de abstração) + provider LaunchDarkly.
   - Avaliar flag por contexto (tenant, ambiente, usuário/grupo).
   - Implementar fallback seguro para indisponibilidade do provider.

4. **Integrar no CI/CD (GitHub)**
   - Guardar SDK key/token em GitHub Secrets (nunca em código).
   - Exigir no PR a seção de "Plano de Toggle e Rollout" quando a estratégia for `flag`.
   - Manter deploy desacoplado de release: deploy pode ocorrer com flag OFF.

5. **Operar em homologações paralelas**
   - Nova frente entra com flag OFF.
   - Rollout gradual em `hml` e depois `prod` por segmento.
   - Kill switch pronto para desativação imediata.
   - Após estabilização, remover flag e dívida associada.

## Compatibilidade com GitHub Enterprise

### GitHub Enterprise Cloud

Suporte direto para o fluxo acima: GitHub Actions + Secrets + revisão de PR.

### GHES (GitHub Enterprise Server)

Também é compatível, com pré-requisitos de infraestrutura:

- runners com saída para endpoints LaunchDarkly;
- secrets gerenciados no GHES/infra corporativa;
- em ambiente air-gapped, uso de proxy/egress controlado e fallback operacional.

## Guardrails recomendados

- Não usar `direct` em S3/S4 sem justificativa explícita no ADL.
- Em 3+ homologações concorrentes, usar flag com default OFF.
- Exigir testes para caminhos ON/OFF.
- Criar tarefa/issue de remoção da flag com prazo e owner.
