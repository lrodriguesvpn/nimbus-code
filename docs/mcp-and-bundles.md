# MCP Servers e Bundles do Spec Kit

## Pergunta

Servidores MCP (ex.: Atlassian Rovo para JIRA, `ado` para Azure DevOps) podem
ser incluídos no bundle?

## Resposta

**Não como provisionamento real — só como declaração informativa.**

Investigando o código-fonte do `specify-cli` (`bundler/models/manifest.py` e
`bundler/services/resolver.py`), o único lugar onde "MCP" aparece no schema de
manifesto é:

```yaml
requires:
  mcp:
    - "atlassian-rovo (JIRA)"
```

E o único efeito desse campo, no `resolver.py`:

```python
if manifest.requires.mcp:
    warnings.append("Requires MCP servers: " + ", ".join(manifest.requires.mcp))
```

Ou seja: `specify bundle install`/`specify extension add` apenas **exibe um
aviso em texto** listando os servidores MCP necessários — não instala, não
configura, não verifica se estão disponíveis, e não tem qualquer outro efeito
runtime. O Spec Kit não tem (e não pretende ter) um sistema de gestão de
lifecycle de servidores MCP; isso é responsabilidade de cada agente/host
(Copilot CLI, Claude Code, etc.), tipicamente via `.vscode/mcp.json` ou
configuração equivalente do host.

## O que isso significa na prática para o bundle da VPN Dev

- A extensão `vpndev-backlog-sync` **declara** `requires.mcp` (ver
  [`extensions/vpndev-backlog-sync/extension.yml`](../extensions/vpndev-backlog-sync/extension.yml))
  para que quem instalar veja o aviso e saiba que precisa configurar o MCP da
  Atlassian Rovo ou do Azure DevOps antes de usar o hook de sincronização.
- **Não é possível** shipar a configuração real do servidor MCP (endpoint,
  credenciais, modo de autenticação) dentro do bundle de forma que o Spec Kit
  a aplique automaticamente.
- Se quisermos padronizar a configuração de MCP entre projetos da VPN Dev, a
  forma correta é **shipar um arquivo de configuração de exemplo** (ex.:
  `.vscode/mcp.json.example`) como um arquivo comum dentro do preset ou da
  extensão — copiado manualmente pelo desenvolvedor, mas nunca "instalado" pelo
  mecanismo de pacotes do Spec Kit.

## Servidores MCP relevantes por plataforma (referência para `requires.mcp`)

Levantamento (pesquisado em ago/2026) dos servidores MCP mais relevantes por
plataforma, para uso como referência ao declarar `requires.mcp` em futuras
extensões da VPN Dev ou ao preencher `.vscode/mcp.json` em cada projeto. **Nenhum
destes é instalado pelo bundle** — a tabela é só um catálogo de candidatos
avaliados, na mesma lógica descrita acima para Atlassian Rovo/Azure DevOps.

| Plataforma | Servidor MCP | Oficial? | Repositório / instalação | Escopo típico |
| --- | --- | --- | --- | --- |
| **GitHub** | GitHub MCP Server | ✅ GitHub | [`github/github-mcp-server`](https://github.com/github/github-mcp-server) — remoto em `https://api.githubcopilot.com/mcp/`, ou binário local | Repos, Issues/PRs, Actions/CI, code scanning/Dependabot, discussions — candidato natural para sincronizar backlog via GitHub Issues/Projects em vez de JIRA/Azure DevOps |
| **Microsoft 365** | Microsoft 365 MCP Server | ⚠️ Comunidade (via Graph API) | [`softeria/ms-365-mcp-server`](https://github.com/softeria/ms-365-mcp-server) (`npx @softeria/ms-365-mcp-server`) | Outlook, Calendar, Teams, Planner, SharePoint, OneDrive — 300+ ferramentas 1:1 com endpoints do Microsoft Graph |
| **Microsoft 365** | Microsoft 365 Agents Toolkit / Copilot Chat (catálogo Microsoft) | ✅ Microsoft | listado em [`microsoft/mcp`](https://github.com/microsoft/mcp) (catálogo oficial de servidores MCP da Microsoft) | Construção/depuração de agentes M365 Copilot; não é o mesmo escopo de dados do servidor da Softeria acima |
| **Azure** | Azure MCP Server | ✅ Microsoft | [`microsoft/mcp`](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/README.md) (sucessor do `Azure/azure-mcp`, arquivado em ago/2025); extensão `ms-azuretools.vscode-azure-mcp-server` no VS Code | 40+ serviços Azure (Resource Graph, Storage, Cosmos DB, AKS, Monitor, Key Vault etc.) — mesma família de ferramentas usada pelo `azure-*` MCP já configurado neste ambiente |
| **Google Workspace (GWS)** | Workspace MCP | ⚠️ Comunidade (não é produto oficial do Google) | [`taylorwilsdon/google_workspace_mcp`](https://github.com/taylorwilsdon/google_workspace_mcp) | 12 serviços do Workspace (Gmail, Drive, Calendar, Docs, Sheets, Chat etc.), 120+ ferramentas, OAuth 2.1 multi-usuário |
| **Google Cloud (GCP)** | MCP Toolbox for Databases | ✅ Google (`googleapis`) | [`googleapis/mcp-toolbox`](https://github.com/googleapis/mcp-toolbox) (ex-`genai-toolbox`) | BigQuery, AlloyDB, Cloud SQL, Spanner, Firestore, Dataplex — acesso/consulta a dados gerenciados no GCP |
| **Google Cloud (GCP)** | Cloud Run MCP | ✅ Google (`GoogleCloudPlatform`) | [`GoogleCloudPlatform/cloud-run-mcp`](https://github.com/GoogleCloudPlatform/cloud-run-mcp) (`npx @google-cloud/cloud-run-mcp`) | Deploy, listagem e logs de serviços Cloud Run — relevante para o roteiro de implantação do Security/DevSecOps Gate |

**Nota sobre "oficial"**: GitHub, Azure e os dois servidores do Google Cloud são
mantidos pelos próprios fornecedores; o servidor de Microsoft 365 (Graph) e o de
Google Workspace mais adotados hoje são **projetos de comunidade** — avalie
segurança/suporte antes de declarar como dependência obrigatória em qualquer
extensão da VPN Dev.

Ver também o diagrama do ecossistema MCP em
[`docs/bundle-architecture.md`](bundle-architecture.md#5-ecossistema-de-mcp-servers-candidatos).
