#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const index_js_1 = require("@modelcontextprotocol/sdk/server/index.js");
const stdio_js_1 = require("@modelcontextprotocol/sdk/server/stdio.js");
const types_js_1 = require("@modelcontextprotocol/sdk/types.js");
const templates = {
    constitution: '# Constituição do Projeto\n\n## Princípios\n\n1. Especificação antes do código.\n2. Testes proporcionais ao risco.\n3. Segredos fora do Git.\n',
    spec: '# Feature Specification: [Nome]\n\n## Visão geral\n\n[Descreva o resultado esperado.]\n\n## Cenários BDD\n\n- Dado [contexto], quando [ação], então [resultado].\n',
    plan: '# Plano de Implementação: [Nome]\n\n## Arquitetura\n\n[Módulos e dependências afetadas.]\n\n## Validação\n\n[Comandos e cenários de validação.]\n',
    tasks: '# Tarefas: [Nome]\n\n- [ ] Definir a especificação.\n- [ ] Planejar a implementação.\n- [ ] Implementar e validar.\n',
};
const server = new index_js_1.Server({ name: 'nimbus-code-mcp-lite', version: '0.1.0' }, { capabilities: { tools: {} } });
server.setRequestHandler(types_js_1.ListToolsRequestSchema, async () => ({
    tools: [
        {
            name: 'nimbus_lite_get_template',
            description: 'Retorna um template Lite local para constituicao, especificacao, plano ou tarefas.',
            inputSchema: {
                type: 'object',
                properties: {
                    artifact: {
                        type: 'string',
                        enum: Object.keys(templates),
                        description: 'Artefato SDD desejado.',
                    },
                },
                required: ['artifact'],
            },
        },
        {
            name: 'nimbus_lite_getting_started',
            description: 'Explica o fluxo Lite local de especificacao, planejamento e validacao.',
            inputSchema: { type: 'object', properties: {} },
        },
    ],
}));
server.setRequestHandler(types_js_1.CallToolRequestSchema, async (request) => {
    if (request.params.name === 'nimbus_lite_getting_started') {
        return {
            content: [
                {
                    type: 'text',
                    text: 'Comece descrevendo a feature, registre a especificacao, planeje a menor mudanca completa e execute a validacao correspondente.',
                },
            ],
        };
    }
    if (request.params.name === 'nimbus_lite_get_template') {
        const artifact = request.params.arguments?.artifact;
        if (typeof artifact !== 'string' || !(artifact in templates)) {
            throw new Error('artifact deve ser constitution, spec, plan ou tasks.');
        }
        return {
            content: [{ type: 'text', text: templates[artifact] }],
        };
    }
    throw new Error(`Ferramenta Lite desconhecida: ${request.params.name}`);
});
async function run() {
    await server.connect(new stdio_js_1.StdioServerTransport());
}
run().catch((error) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`Erro fatal no MCP Lite do Nimbus Code: ${message}`);
    process.exit(1);
});
