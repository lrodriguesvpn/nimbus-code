# data-model.md — Feature 001: Catálogo de Conteúdo Reutilizável

> Gerado retroativamente. Não há "entidades de domínio" no sentido tradicional
> (esta feature não introduz um serviço com banco de dados) — o "modelo de
> dados" aqui é o schema do arquivo estático `docs/reuse-catalog.yaml`.

## Entidade: Reuse Catalog Entry

Cada entrada do catálogo (`docs/reuse-catalog.yaml`, chave `entries[]`)
representa um padrão/decisão técnica reutilizável já resolvido em uma feature
anterior.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `tag` | string (kebab-case) | Sim | Slug curto e estável — usado para busca (grep/consulta manual) |
| `bounded_context` | string | Sim | Módulo/serviço onde o padrão vive |
| `description` | string (texto livre, 1-2 frases) | Sim | O que é e quando reaproveitar |
| `source` | string (path) | Sim | Caminho para o `spec.md`/`plan.md` original que introduziu o padrão |
| `adr` | string (path, opcional) | Não | Caminho para o ADR relacionado, se houver |
| `reuse_count` | number | Sim | Nº de vezes que outra feature já referenciou esta entrada — incrementado manualmente ao reaproveitar, sinal de ROI do catálogo |

**Regras de validação** (curatoriais, não impostas por schema automatizado
nesta fase — ver "Fora de Escopo" no `spec.md`):
- `tag` deve ser único dentro do arquivo.
- `source` deve apontar para um arquivo real existente no repositório no
  momento em que a entrada é adicionada.
- Preenchimento é manual/curatorial — sem automação de indexação (decisão
  registrada em `research.md`).

## Relação com outras entidades do bundle (por ponteiro, não por valor)

```text
Reuse Catalog Entry  ──referenciada por──>  plan.md de uma feature nova
                                             (campo "Padrão reutilizado
                                             encontrado?" na Classificação
                                             de Complexidade)
Reuse Catalog Entry  ──complementar a──>     Harness Catalog Entry (feature 011)
                                             — reuse cataloga soluções,
                                             harness cataloga erros
Reuse Catalog Entry  ──complementar a──>     Success Catalog Entry (feature 012)
                                             — reuse cataloga PADRÕES técnicos
                                             reutilizáveis; success cataloga
                                             DECISÕES/abordagens que deram
                                             certo (escopo mais amplo que
                                             só técnico)
```
