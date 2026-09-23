# Nimbus Code Lite

Nimbus Code Lite e uma distribuicao local com codigo-fonte disponivel, para
iniciar praticas de Spec-Driven Development (SDD): especificacao, planejamento,
tarefas e validacao. Ela e adequada para aprendizado, avaliacao e projetos
locais.

> Esta distribuicao contem somente os componentes Lite. Ela nao inclui codigo,
> catalogos ou automacoes da oferta Enterprise da Venha Pra Nuvem.

## Componentes

- **Extensao VS Code Lite** para inicializar os artefatos SDD no workspace.
- **MCP Lite** com templates locais para constituicao, especificacao, plano e tarefas.
- **Preset Community** com os mesmos templates em Markdown.

## Como usar

### Extensao VS Code

```bash
cd extensions/vscode
npm install
npm run compile
npm run package
```

Instale o arquivo `.vsix` gerado e execute **Nimbus Code Lite: Inicializar
Repositorio** pela Command Palette.

### MCP Lite

```bash
cd servers/mcp-nimbus
npm install
npm run build
node dist/index.js
```

O servidor expoe apenas os tools `nimbus_lite_get_template` e
`nimbus_lite_getting_started`.

## Oferta Enterprise

O Nimbus Code Enterprise e uma oferta comercial separada da Venha Pra Nuvem.
Para conhecer a oferta e obter suporte especializado, acesse
[venhapranuvem.com.br](https://venhapranuvem.com.br) ou escreva para
[contato@venhapranuvem.com.br](mailto:contato@venhapranuvem.com.br).

## Licenca

Nimbus Code Lite usa a **Business Source License 1.1 (BSL 1.1)**: e gratuito
para avaliacao, educacao, testes nao produtivos e uso pessoal. Producao ou uso
comercial requer licenca da Venha Pra Nuvem. Consulte [LICENSE](LICENSE).
