<!--
  Cole esta seção no README raiz do seu projeto e mantenha os valores atualizados
  manualmente a cada atualização aprovada do bundle/Nimbus Code. Não edite a versão
  aqui sem antes ter aprovado e aplicado a atualização correspondente — ver a
  política de versionamento em
  https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code#versão-do-bundle-em-uso--política-de-atualização
-->

## Nimbus Code — NIMBUS CODE / Padrões Nimbus-Code

Este projeto usa o [GitHub Spec Kit](https://github.com/github/spec-kit) com os
padrões corporativos da Nimbus-Code aplicados via **NIMBUS CODE™ AI Delivery
System**.

| Item | Versão instalada |
| --- | --- |
| **Nimbus Code CLI** | `0.16.1` |
| **Bundle `nimbus-code-project-bundle`** ([nimbus-code](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code)) | `1.22.1` |
| — preset `nimbus-code-standards` | `1.22.1` |
| — extensão `nimbus-code-backlog-sync` | `1.2.0` |
| — workflow `nimbus-code-full-cycle` | `1.4.0` |

O bundle também instala o fluxo de descoberta **`/speckit-interview`**, que
gera `specs/<feature>/interview.md` antes do `/speckit-specify` e valida a
completude da entrevista com um script determinístico.

Quando o bundle muda, o mesmo `bootstrap.sh`/sync usado na inicialização pode
ser rerodado para reidratar arquivos locais copiados que tenham sido removidos
ou estejam fora de sincronia.

**Atualizar a versão acima requer aprovação formal** (mesma regra do próprio
Nimbus Code) — não altere por conta própria fora do fluxo do PR automático semanal
(`.github/workflows/update-speckit-and-bundle.yml`).

> **Importante:** `nimbus-code` é o repositório
> **template/foundation**. Artefatos de produto/marketing ficam no repositório satélite `nimbus-code-mkt` e/ou no repositório público — e não substituem esta dependência técnica.
