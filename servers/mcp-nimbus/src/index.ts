#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const server = new Server(
  {
    name: "nimbus-code-mcp-server",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Catálogo de Ferramentas expostas pelo Squad Nimbus Code
const TOOLS = [
  {
    name: "nimbus_intake_interview",
    description: "Conduz ou processa a entrevista de descoberta nos 4 blocos obrigatórios (Negócio, Infraestrutura, Segurança e LGPD).",
    inputSchema: {
      type: "object",
      properties: {
        feature_slug: { type: "string", description: "Slug da feature" },
        transcript: { type: "string", description: "Transcrição opcional da entrevista" }
      },
      required: ["feature_slug"]
    }
  },
  {
    name: "nimbus_generate_spec",
    description: "Gera a especificação funcional SMART e cenários BDD a partir da entrevista.",
    inputSchema: {
      type: "object",
      properties: {
        feature_slug: { type: "string", description: "Slug da feature" }
      },
      required: ["feature_slug"]
    }
  },
  {
    name: "nimbus_plan_architecture",
    description: "Desenha a arquitetura técnica, registra ADRs e atualiza o grafo de dependências.",
    inputSchema: {
      type: "object",
      properties: {
        feature_slug: { type: "string", description: "Slug da feature" }
      },
      required: ["feature_slug"]
    }
  },
  {
    name: "nimbus_generate_tasks",
    description: "Gera a estratégia de testes e tasks.md ordenadas por dependência com paralelismo [P].",
    inputSchema: {
      type: "object",
      properties: {
        feature_slug: { type: "string", description: "Slug da feature" }
      },
      required: ["feature_slug"]
    }
  },
  {
    name: "nimbus_build_autonomous",
    description: "Executa a implementação de código com testes e PR rastreável.",
    inputSchema: {
      type: "object",
      properties: {
        feature_slug: { type: "string", description: "Slug da feature" },
        task_id: { type: "string", description: "ID da task opcional" }
      },
      required: ["feature_slug"]
    }
  }
];

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: TOOLS,
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  return {
    content: [
      {
        type: "text",
        text: `[Nimbus Code MCP] Ferramenta '${name}' executada com sucesso em modo Local/DevX. Argumentos: ${JSON.stringify(args)}`
      }
    ]
  };
});

async function run() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

run().catch((error) => {
  console.error("Erro fatal no servidor Nimbus Code MCP:", error);
  process.exit(1);
});
