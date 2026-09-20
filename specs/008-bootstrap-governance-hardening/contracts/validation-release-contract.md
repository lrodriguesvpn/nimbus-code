# Contrato de Release Candidate e Ref do Bootstrap

## Objetivo

Definir a ref imutável usada pelo projeto piloto e a relação entre as versões
dos bundles e presets publicados no mesmo commit.

## Contrato

| Campo | Valor da RC |
|---|---|
| Git ref | `v1.19.0-rc.1` |
| Bundle de projeto | `nimbus-code-project-bundle` `1.19.0` |
| Preset Dev Standards | `nimbus-code-standards` `1.19.0` |
| Bundle de plataforma | `nimbus-code-platform-bundle` `0.5.0` |
| Preset Platform | `nimbus-code-platform-standards` `0.5.0` |

## Regras

1. A tag deve apontar para um commit já promovido à `main`.
2. O bootstrap do piloto deve receber `--ref v1.19.0-rc.1`.
3. O bootstrap deve registrar a ref em `.nimbus/bootstrap.json`.
4. Nenhum cenário do piloto pode usar `main`, uma branch móvel ou cópia manual
   dos templates.
5. A tag final `v1.19.0` só pode ser criada após os gates de segurança, piloto
   e estabilidade definidos em [`impact-map.md`](../impact-map.md).
6. Se houver falha, a correção deve gerar nova RC (`v1.19.0-rc.2`), nunca
   sobrescrever ou mover uma tag existente.

## Compatibilidade

O bump MINOR preserva compatibilidade dos consumidores existentes. Projetos já
bootstrapados não são atualizados automaticamente; somente novos bootstraps ou
um upgrade explícito consumirão a nova ref.
