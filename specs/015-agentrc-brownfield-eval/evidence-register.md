# Evidence Register: AgentRC Brownfield Evaluation

| Evidence ID | Fonte | Tipo | Localização | Confiabilidade | Observação |
|---|---|---|---|---|---|
| ER-001 | AgentRC public repository documentation | Public docs | https://github.com/microsoft/agentrc | Alta | Fonte primária para capacidades declaradas |
| ER-002 | Project constitution | Internal governance | `.specify/memory/constitution.md` | Alta | Define MUST controls non-negotiable |
| ER-003 | Brownfield context-awareness feature | Internal spec | `specs/014-brownfield-multirepo-context-awareness/` | Alta | Referência de contexto multi-repo e grafo |
| ER-004 | Existing Speckit workflows and templates | Internal artifacts | `.github/skills/` and `.specify/presets/` | Alta | Base atual do fluxo spec→plan→tasks |
| ER-005 | This feature design artifacts | Internal plan/research | `specs/015-agentrc-brownfield-eval/plan.md` and `research.md` | Alta | Consolida decisão e limites de escopo |

## Source Reliability Criteria

- **Alta**: documentação oficial ou artefato versionado do repositório.
- **Média**: observação indireta sem validação formal.
- **Baixa**: hipótese sem evidência rastreável.

## Evaluation Boundary

- Não há execução local obrigatória do AgentRC nesta fase.
- Conclusões dependentes de integração prática ficam explicitamente marcadas como hipótese para piloto.
