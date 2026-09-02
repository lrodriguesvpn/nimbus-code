<!--
  Cole esta seção no README raiz do seu projeto e mantenha os valores atualizados
  manualmente a cada atualização aprovada do bundle/Nimbus Code. Não edite a versão
  aqui sem antes ter aprovado e aplicado a atualização correspondente — ver a
  política de versionamento em
  https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template#versão-do-bundle-em-uso--política-de-atualização
-->

## Nimbus Code — NIMBUS CODE / Padrões Nimbus-Code

Este projeto usa o [GitHub Spec Kit](https://github.com/github/spec-kit) com os
padrões corporativos da Nimbus-Code aplicados via **NIMBUS CODE™ AI Delivery
System**.

| Item | Versão instalada |
| --- | --- |
| **Nimbus Code CLI** | `0.16.1` |
| **Bundle `nimbus-code-project-bundle`** ([nimbus-code-spec-kit-template](https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template)) | `1.18.0` |
| — preset `nimbus-code-standards` | `1.18.0` |
| — extensão `nimbus-code-backlog-sync` | `1.0.0` |
| — workflow `nimbus-code-full-cycle` | `1.0.0` |

O bundle também instala o fluxo de descoberta **`/speckit-interview`**, que
gera `specs/<feature>/interview.md` antes do `/speckit-specify` e valida a
completude da entrevista com um script determinístico.

Quando o bundle muda, o mesmo `bootstrap.sh`/sync usado na inicialização pode
ser rerodado para reidratar arquivos locais copiados que tenham sido removidos
ou estejam fora de sincronia.

**Atualizar a versão acima requer aprovação formal** (mesma regra do próprio
Nimbus Code) — não altere por conta própria fora do fluxo do PR automático semanal
(`.github/workflows/update-speckit-and-bundle.yml`).

> **Importante:** `nimbus-code-spec-kit-template` é o repositório
> **template/foundation**. O repositório `nimbus-code` é o repositório
> **produto/marketing** e não substitui esta dependência técnica.
