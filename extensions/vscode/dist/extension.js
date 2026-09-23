"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = require("vscode");
const CONSTITUTION = `# Constituição do Projeto (Nimbus Code Lite)

## Princípios

1. **Especificação antes do código:** descreva o resultado esperado antes de implementar.
2. **Testes proporcionais ao risco:** valide cada mudança com o menor teste confiável.
3. **Segredos fora do Git:** nunca versione credenciais ou tokens.
4. **Escopo explícito:** altere apenas os arquivos necessários para a tarefa.
`;
const SPEC_TEMPLATE = `# Feature Specification: [Nome]

**Slug:** \`[slug]\`

## Visão geral

[Descreva o problema e o resultado esperado.]

## Requisitos SMART

- **Específico:** [resultado]
- **Mensurável:** [métrica]
- **Atingível:** [restrições]
- **Relevante:** [valor]
- **Temporal:** [prazo]

## Cenários BDD

- **Dado** [contexto], **quando** [ação], **então** [resultado].
`;
const PLAN_TEMPLATE = `# Plano de Implementação: [Nome]

## Arquitetura

[Módulos, interfaces e dependências afetadas.]

## Validação

[Comandos e cenários que comprovam o resultado.]
`;
const TASKS_TEMPLATE = `# Tarefas: [Nome]

- [ ] Definir a especificação.
- [ ] Planejar a implementação.
- [ ] Implementar a menor alteração completa.
- [ ] Executar a validação.
`;
function activate(context) {
    const output = vscode.window.createOutputChannel('Nimbus Code Lite');
    context.subscriptions.push(output);
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.initRepository', async () => {
        const workspace = vscode.workspace.workspaceFolders?.[0];
        if (!workspace) {
            vscode.window.showWarningMessage('Abra uma pasta ou repositório antes de inicializar o Nimbus Code Lite.');
            return;
        }
        const root = workspace.uri;
        const templates = vscode.Uri.joinPath(root, '.specify', 'templates');
        const files = [
            [vscode.Uri.joinPath(root, 'constitution.md'), CONSTITUTION],
            [vscode.Uri.joinPath(templates, 'spec-template.md'), SPEC_TEMPLATE],
            [vscode.Uri.joinPath(templates, 'plan-template.md'), PLAN_TEMPLATE],
            [vscode.Uri.joinPath(templates, 'tasks-template.md'), TASKS_TEMPLATE],
        ];
        try {
            await vscode.workspace.fs.createDirectory(templates);
            for (const [uri, content] of files) {
                try {
                    await vscode.workspace.fs.stat(uri);
                    output.appendLine(`Mantido arquivo existente: ${uri.fsPath}`);
                }
                catch {
                    await vscode.workspace.fs.writeFile(uri, Buffer.from(content, 'utf8'));
                }
            }
            vscode.window.showInformationMessage('Nimbus Code Lite inicializado. Comece pela especificação da sua feature.');
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            vscode.window.showErrorMessage(`Não foi possível inicializar o Nimbus Code Lite: ${message}`);
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.openLiteGuide', async () => {
        await vscode.env.openExternal(vscode.Uri.parse('https://venhapranuvem.com.br'));
    }));
}
function deactivate() { }
