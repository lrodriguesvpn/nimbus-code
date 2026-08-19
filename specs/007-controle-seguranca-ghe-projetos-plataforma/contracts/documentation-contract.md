# Contract: Documentação de Baseline de Segurança (`docs/security-baseline-ghe.md`)

**Feature**: `007-controle-seguranca-ghe-projetos-plataforma`

Este contrato define a estrutura mínima obrigatória que `docs/security-baseline-ghe.md`
deve conter para satisfazer os Functional Requirements do `spec.md`. É o "contrato de
saída" da camada de documentação — usado como checklist de revisão do PR e como
critério de teste de integração `tests/docs/security-baseline-checklist.test.sh`.

## Seções obrigatórias

1. **Baseline de Repositório de Projeto** (atende FR-001)
   - Acesso (papéis e princípio de menor privilégio)
   - Branch protection (regras mínimas: revisão obrigatória, status checks, no force-push)
   - Regras de revisão de PR (nº mínimo de aprovadores, CODEOWNERS)
   - Permissões de GitHub Actions (read/write mínimo necessário)
   - Secrets (o que pode/não pode ser secret de repositório vs. organização)

2. **Governança do Projeto Plataforma** (atende FR-002)
   - Diferenciação explícita entre controles de repositório e controles do Project V2 consolidado
   - Modelo de acesso a views/campos críticos do Project V2

3. **Modelo de Acesso por Papéis** (atende FR-003)
   - Tabela: papel → permissões → quando usar (repositório e Projeto Plataforma)

4. **Padrão de Tokens e Secrets de Automação** (atende FR-004, FR-004a)
   - Escopo mínimo por tipo de credencial (PAT vs. GitHub App)
   - Regra: varredura org-wide usa GitHub App dedicado (nunca PAT de usuário) — referenciar ADR-0008
   - Rotação, armazenamento (GitHub Secrets) e revogação

5. **Checklist Operacional de Auditoria** (atende FR-005, FR-005a, FR-005b)
   - Lista de controles com critério objetivo `ok`/`pendente`/`risco`
   - Frequência: scan semanal automatizado + relatório mensal consolidado
   - Escopo: todos os repositórios da organização (descoberta automática via API)

6. **Procedimento de Não Conformidade** (atende FR-006)
   - Como um desvio detectado pela automação vira Issue rastreável
   - Campos obrigatórios da issue: prioridade, responsável, prazo, critério de validação de correção

7. **Referência ao Fluxo Nimbus Code** (atende FR-007)
   - Ponteiro (link) para `docs/label-taxonomy-and-autonomous-dev.md` e para o board — sem duplicar conteúdo

8. **Dependências de Workflows com Projects** (atende FR-008)
   - Permissões e secrets mínimos exigidos por qualquer workflow que leia/escreva em Projects V2

## Critério de aceite do contrato

- `tests/docs/security-baseline-checklist.test.sh` verifica, via grep de headings, que as 8 seções acima existem no arquivo publicado.
- Nenhuma seção pode apenas re-explicar o fluxo Nimbus Code já documentado alhures — deve referenciar por link (regra de reuso da constituição).
