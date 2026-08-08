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
