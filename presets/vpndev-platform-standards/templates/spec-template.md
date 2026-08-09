<!--
  Este bloco é inserido pelo preset `vpndev-platform-standards` (estratégia
  `prepend`) antes do spec-template.md nativo do Spec Kit, adicionando campos
  obrigatórios de identificação de cliente/ambiente/legado. O restante da spec
  continua sendo preenchido normalmente pelo /speckit-specify.
-->

## VPN Dev (Plataforma) — Cabeçalho Obrigatório da Spec

*Preencher ANTES dos critérios de aceitação. Alimenta o plan.md e o
platform-graph.yaml.*

| Campo | Valor |
|---|---|
| **Feature slug** | `<kebab-case-slug>` — usado como nome da pasta em `specs/` |
| **Cliente/Tenant** | [ex.: Venha Pra Nuvem (piloto interno), Cliente X] |
| **Ambiente(s)** | prod · hml · dev |
| **Nuvem(ns)/plataforma(s) envolvidas** | Azure · AWS · GCP · GWS · M365 · D365 |
| **Sistema legado (não-Terraformado hoje)?** | Sim/Não — se Sim, referenciar `legacy-inventory.md` |
| **Esta feature aplica mudança direta em algum ambiente?** | **Não** *(sempre "Não" neste repositório)* |
| **PR de referência / Issue** | [link — ou "novo" se não existir] |

> Se a resposta de "aplica mudança direta" for "Sim", esta spec está no
> repositório errado — mudanças reais nascem em um repositório de projeto
> (`vpndev-standards`), nunca aqui.

## VPN Dev (Plataforma) — Critérios de Aceitação (formato BDD)

*Cada critério deve incluir o resultado esperado da reconciliação (zero-diff),
não apenas o comportamento funcional.*

> **AC-1**
> **Given** [estado atual documentado no inventário]
> **When** [extração/reconciliação executada com a ferramenta do domínio]
> **Then** [diff vazio confirmado / evidência anexada]
> **Test ref:** `test_AC1_<descricao>`

> *(Adicionar AC-N conforme necessário.)*

{CORE_TEMPLATE}
