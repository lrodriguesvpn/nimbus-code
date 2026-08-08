# speckit-vpndev-standards

Padrões corporativos de **Spec-Driven Development** (GitHub Spec Kit) da
**VPN Dev**, distribuídos como um **bundle** único para que todo projeto novo já
nasça com governança, gate de segurança/DevSecOps e integração de backlog
consistentes — sem que cada time precise reescrever essas regras.

## O que este repositório contém

| Componente | Pasta | O que faz |
|---|---|---|
| **Preset** `vpndev-standards` | [`presets/vpndev-standards/`](presets/vpndev-standards/) | Injeta os princípios não-negociáveis da empresa na constituição (`wrap`) e acrescenta o Security/DevSecOps Gate + Architecture Decision Log ao `plan.md` e o checklist de qualidade ao `tasks.md` (`append`) — sem remover nada do Spec Kit nativo. |
| **Extensão** `vpndev-backlog-sync` | [`extensions/vpndev-backlog-sync/`](extensions/vpndev-backlog-sync/) | Sincroniza specs/tasks com JIRA ou Azure DevOps via MCP, como hook opcional após `/speckit-specify` e `/speckit-tasks`. |
| **Workflow** `vpndev-full-cycle` | [`workflows/vpndev-full-cycle/`](workflows/vpndev-full-cycle/) | Ciclo SDD completo com um gate explícito de DevSecOps entre `plan` e `tasks`. |
| **Bundle** `vpndev-project-bundle` | [`bundles/vpndev-project-bundle/`](bundles/vpndev-project-bundle/) | Amarra as três peças acima numa "receita" instalável de uma vez, com versões pinadas. |

Cada peça é independentemente versionada (SemVer) e pode ser instalada isolada —
ver o README de cada pasta.

## Como um projeto novo já nasce com isso

```bash
curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/bootstrap.sh | bash
```

Isso executa `specify init` (se ainda não inicializado) e instala preset +
extensão + workflow na versão publicada mais recente da branch `main`.

> **Nota sobre `specify bundle install`**: o CLI do Spec Kit resolve os
> componentes de um bundle (`provides.presets/extensions/workflows`) **somente
> através de um catálogo registrado** — o campo `source` do `bundle.yml` é só
> metadado de proveniência, não um mecanismo de download. Por isso este repo
> publica tanto os artefatos via GitHub Releases quanto os `catalog.json` de
> cada tipo (`presets/catalog.json`, `extensions/catalog.json`,
> `workflows/catalog.json`, `bundles/catalog.json`). Depois de registrar os
> catálogos uma vez (ver [Publicação e Catálogo](#publicação-e-catálogo)),
> `specify bundle install vpndev-project-bundle` funciona como um comando único.

## Versão do Bundle em uso — Política de Atualização

**A versão do bundle instalada em um projeto só muda mediante aprovação
formal** — da mesma forma que a versão do próprio Spec Kit CLI. Isso existe
para que nenhum projeto tenha seu `plan.md`/`constitution.md`/workflow
alterados silenciosamente por uma atualização de política organizacional no
meio de uma feature em andamento.

Fluxo de atualização:

1. Uma mudança neste repositório (preset/extensão/workflow) é revisada e
   aprovada via PR normal.
2. Uma nova versão do bundle é publicada (ver [Versionamento](#versionamento))
   **somente** depois da aprovação — nunca antes.
3. Cada projeto consumidor recebe, semanalmente, uma **issue automática**
   (workflow `update-speckit-and-bundle.yml`, ver
   [`templates/workflows/`](templates/workflows/)) comparando sua versão
   instalada com a mais recente publicada aqui — **essa issue nunca aplica a
   atualização sozinha**, apenas avisa e traz os comandos exatos a rodar; a
   atualização em si sempre vira um PR normal, revisado como qualquer outra
   mudança de dependência.

Todo projeto que consome este bundle deve documentar, no seu próprio README, a
versão instalada — ver o modelo em
[`templates/README-bundle-section.md`](templates/README-bundle-section.md).

## Versionamento

Cada componente (preset, extensão, workflow, bundle) segue
[SemVer](https://semver.org/) de forma independente, mas o **bundle sempre pina
versões exatas** dos componentes que referencia (nunca ranges) — para que
`vpndev-project-bundle vX.Y.Z` seja sempre reproduzível.

Mudar qualquer arquivo em `presets/`, `extensions/` ou `workflows/` é uma
**mudança de política organizacional**: requer PR revisado pelo time responsável
pelos padrões da VPN Dev antes de publicar uma nova versão de bundle. Não é
uma decisão de projeto individual.

## Publicação e Catálogo

Releases são publicadas via tag `vX.Y.Z` — o workflow
[`.github/workflows/release.yml`](.github/workflows/release.yml) empacota cada
componente em `.zip` e anexa como assets da GitHub Release correspondente. Os
arquivos `catalog.json` em `presets/`, `extensions/`, `workflows/` e `bundles/`
apontam para esses assets e são atualizados no mesmo PR que muda a versão.

Para registrar os catálogos uma vez por projeto (ou uma vez por máquina, em
`~/.specify/*-catalogs.yml`):

```bash
specify preset catalog add \
  https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/presets/catalog.json \
  --name vpndev --priority 5 --install-allowed

specify extension catalog add \
  https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/extensions/catalog.json \
  --name vpndev --install-allowed

specify workflow catalog add \
  https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/workflows/catalog.json \
  --name vpndev

specify bundle catalog add \
  https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/bundles/catalog.json \
  --id vpndev --priority 5 --policy install-allowed
```

Depois disso, `specify bundle install vpndev-project-bundle --integration copilot`
funciona como um comando único, em qualquer diretório (novo ou existente).

> ⚠️ **Este repositório é privado.** Diferente de um repo público, as URLs
> `raw.venha-pra-nuvem.ghe.com/...` acima **exigem autenticação** (token) para
> requisições HTTP simples (`curl`, e o fetcher interno do `specify` CLI) — não
> é o mesmo mecanismo de autenticação usado por `git clone`/`gh`, que já
> funciona com as credenciais configuradas na máquina/CI. Por isso, **o caminho
> recomendado e já validado ponta a ponta hoje é o [`bootstrap.sh`](bootstrap.sh)**
> (que usa `git clone` autenticado, não HTTP cru) — o fluxo por catálogo acima
> é o alvo de longo prazo, mas requer configurar um token de leitura para este
> repositório em cada máquina/pipeline que for consumi-lo (ex.:
> `git config --global http.https://venha-pra-nuvem.ghe.com/.extraheader` ou
> equivalente, fora do escopo deste README).

## Extensões candidatas a repositório próprio

Ver análise completa em [`docs/extension-candidates.md`](docs/extension-candidates.md).

## MCP Servers no bundle?

O Spec Kit **não instala nem gerencia** servidores MCP — o bundle/extensão só
pode **declarar** uma dependência informativa (`requires.mcp` em `extension.yml`),
que aparece como aviso na instalação, mas não provisiona nada. Ver detalhes em
[`docs/mcp-and-bundles.md`](docs/mcp-and-bundles.md).

## Estrutura

```text
speckit-vpndev-standards/
├── presets/vpndev-standards/           # preset.yml + templates/
├── extensions/vpndev-backlog-sync/     # extension.yml + commands/
├── workflows/vpndev-full-cycle/        # workflow.yml
├── bundles/vpndev-project-bundle/      # bundle.yml
├── templates/                         # arquivos para copiar em projetos consumidores
│   ├── README-bundle-section.md
│   └── workflows/update-speckit-and-bundle.yml
├── docs/
│   ├── extension-candidates.md
│   └── mcp-and-bundles.md
├── bootstrap.sh
└── .github/workflows/release.yml
```
