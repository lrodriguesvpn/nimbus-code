# Retrospectiva da Feature — `008-bootstrap-governance-hardening`

## O que divergiu do plano?

| Artefato / área | O que estava planejado | O que aconteceu de fato |
|---|---|---|
| `bootstrap.sh` | Selecionar o preset correto e instalar seus componentes | A implementação revelou que componentes de workload também eram instalados no perfil `platform`; o escopo foi ampliado para tornar a separação estrita. |
| Reprodutibilidade | Reexecução idempotente do bootstrap | Foi necessário adicionar pin de `--ref`/`--version`, metadata auditável e falha explícita para instalações críticas. |
| Validação | Testes da seleção de preset | Foram adicionados testes de metadata, falha de instalação e isolamento completo do perfil `platform`. |

## Causa raiz da(s) divergência(s)

- [x] O bootstrap concentrava componentes comuns e específicos de workload no
  mesmo fluxo, sem uma matriz explícita de capacidades por perfil.
- [x] A versão da fonte e o resultado aplicado não tinham um contrato de
  metadata persistido no repositório consumidor.

## Ação para o próximo ciclo

| Ação | Responsável | Data alvo | Issue/PR |
|---|---|---|---|
| Manter testes de contrato para cada perfil sempre que um novo workflow ou extensão for adicionado | Nimbus-Code | 2026-09-30 | Feature 008 |
| Exigir `--ref` apontando para tag em pipelines de produção | Plataforma | 2026-09-30 | Feature 008 |

## Padrões aprendidos elegíveis para o catálogo de reuso

- [x] Padrão identificado: `bootstrap-profile-isolation` —
  componentes de workload devem ser instalados apenas sob uma condição
  explícita de perfil, com teste negativo para o perfil de plataforma.
- [ ] Entrada adicionada ao `docs/reuse-catalog.yaml`
