"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = require("vscode");
const os = require("os");
const https = require("https");
function activate(context) {
    const outputChannel = vscode.window.createOutputChannel('Nimbus Code');
    outputChannel.appendLine('[Nimbus Code] Extensão ativada com sucesso.');
    const config = vscode.workspace.getConfiguration('nimbus');
    const mode = config.get('mode', 'local_unrestricted');
    if (mode === 'local_unrestricted') {
        outputChannel.appendLine('[Nimbus Code] Executando em modo LOCAL IRRESTRITO (Teste & DevX ativo).');
    }
    // Função auxiliar para enviar telemetria/registro de inicialização pública para auditoria e CRM
    async function registerCommunityTelemetry(workspaceName, remoteUrl, userEmail, userName, company) {
        const payload = {
            timestamp: new Date().toISOString(),
            event: 'nimbus_community_init',
            workspace: workspaceName,
            remoteUrl: remoteUrl || 'local_only',
            user: {
                username: userName || os.userInfo().username,
                email: userEmail || 'unknown',
                company: company || 'unknown',
                hostname: os.hostname(),
                platform: os.platform()
            },
            clientVersion: context.extension.packageJSON.version || '1.0.0'
        };
        outputChannel.appendLine(`[Nimbus Code Telemetry] Registrando inicialização pública: ${JSON.stringify(payload)}`);
        // Endpoint webhook/telemetria seguro da Venha Pra Nuvem
        const telemetryUrl = 'https://api.venhapranuvem.com.br/telemetry/nimbus-community';
        try {
            const data = JSON.stringify(payload);
            const urlObj = new URL(telemetryUrl);
            const req = https.request({
                hostname: urlObj.hostname,
                port: 443,
                path: urlObj.pathname,
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(data),
                    'User-Agent': 'Nimbus-Code-VSCode-Extension'
                },
                timeout: 4000
            }, (res) => {
                outputChannel.appendLine(`[Nimbus Code Telemetry] Resposta: ${res.statusCode}`);
            });
            req.on('error', (e) => {
                outputChannel.appendLine(`[Nimbus Code Telemetry] Aviso: Webhook offline ou unreachable (${e.message}). Registro mantido local.`);
            });
            req.write(data);
            req.end();
        }
        catch {
            // Falha silenciosa para não bloquear o desenvolvedor
        }
    }
    // 0. Status Bar Item (Indicador visual sempre visível e clicável)
    const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBarItem.text = '$(rocket) Nimbus Code';
    statusBarItem.tooltip = 'Nimbus Code: Clique para abrir o menu do Squad de Agentes';
    statusBarItem.command = 'nimbus.openSquad';
    statusBarItem.show();
    context.subscriptions.push(statusBarItem);
    // Função auxiliar para validar se há workspace aberto ou oferecer abertura/clonagem de repo
    async function ensureWorkspace() {
        const folders = vscode.workspace.workspaceFolders;
        if (folders && folders.length > 0) {
            return true;
        }
        const choice = await vscode.window.showWarningMessage('⚠️ O Nimbus Code requer uma pasta ou repositório Git aberto para gerenciar especificações e artefatos.', 'Abrir Pasta Local', 'Clonar Repositório Git', 'Continuar Mesmo Assim');
        if (choice === 'Abrir Pasta Local') {
            await vscode.commands.executeCommand('vscode.openFolder');
            return false;
        }
        else if (choice === 'Clonar Repositório Git') {
            const repoUrl = await vscode.window.showInputBox({
                prompt: 'Informe a URL do repositório Git que deseja clonar e abrir:',
                placeHolder: 'https://github.com/usuario/meu-projeto.git'
            });
            if (repoUrl) {
                await vscode.commands.executeCommand('git.clone', repoUrl);
            }
            return false;
        }
        else if (choice === 'Continuar Mesmo Assim') {
            return true;
        }
        return false;
    }
    // Função auxiliar para abrir chat do Copilot com o prompt pronto
    async function triggerChatOrPrompt(queryText) {
        const hasWorkspace = await ensureWorkspace();
        if (!hasWorkspace) {
            return;
        }
        try {
            await vscode.commands.executeCommand('workbench.action.chat.open', { query: queryText });
        }
        catch {
            try {
                await vscode.commands.executeCommand('workbench.action.quickchat.open', { query: queryText });
            }
            catch {
                vscode.window.showInformationMessage(`Nimbus Code: Execute no Chat do Copilot: ${queryText}`);
            }
        }
    }
    // Função auxiliar para detectar se o workspace atual é do GHE da Venha Pra Nuvem
    async function detectVpnEnterpriseEnvironment() {
        try {
            // 1. Checar remotes git do workspace se houver extensão Git do VS Code
            const gitExtension = vscode.extensions.getExtension('vscode.git');
            if (gitExtension) {
                const gitApi = gitExtension.exports.getAPI(1);
                if (gitApi && gitApi.repositories && gitApi.repositories.length > 0) {
                    for (const repo of gitApi.repositories) {
                        const remotes = repo.state.remotes || [];
                        for (const r of remotes) {
                            const url = r.fetchUrl || r.pushUrl || '';
                            if (url.includes('venha-pra-nuvem.ghe.com') || url.includes('venha-pra-nuvem/')) {
                                return { isVpnEnterprise: true, reason: 'Repositório hospedado no GitHub Enterprise da Venha Pra Nuvem', remoteUrl: url };
                            }
                        }
                    }
                }
            }
            // 2. Checar sessões de autenticação do VS Code (GitHub / GHE)
            const gheSession = await vscode.authentication.getSession('github-enterprise', ['repo'], { createIfNone: false });
            if (gheSession && gheSession.account.label.toLowerCase().includes('venha-pra-nuvem')) {
                return { isVpnEnterprise: true, reason: 'Usuário autenticado no GitHub Enterprise da Venha Pra Nuvem' };
            }
        }
        catch {
            // Fallback gracioso
        }
        return { isVpnEnterprise: false };
    }
    // 1. Comandos do Command Palette
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.initRepository', async () => {
        const hasWorkspace = await ensureWorkspace();
        if (!hasWorkspace) {
            return;
        }
        const envCheck = await detectVpnEnterpriseEnvironment();
        const options = [];
        if (envCheck.isVpnEnterprise) {
            options.push({
                label: '🚀 Inicializar Nimbus Code Enterprise (VPN)',
                detail: `Ambiente VPN Detectado (${envCheck.reason}). Instala o bundle completo com 18 agentes nativos e bootstrap.`,
                action: 'enterprise_init'
            });
        }
        options.push({
            label: '🟢 Inicializar Nimbus Code Community (Gratuito / BSL 1.1)',
            detail: 'Configura o fluxo Spec-Driven Development (SDD), constitution.md e templates locais.',
            action: 'community'
        }, {
            label: '🔵 Sobre o Nimbus Code Enterprise (Venha Pra Nuvem)',
            detail: 'Desbloqueia 18 agentes nativos, Harness Corporativo, Harvest Brownfield e Sanfona de Dev.',
            action: 'enterprise_info'
        });
        const choice = await vscode.window.showQuickPick(options, {
            placeHolder: envCheck.isVpnEnterprise
                ? '🏢 Ambiente Enterprise VPN detectado! Selecione o modo de inicialização:'
                : 'Escolha como deseja inicializar o Nimbus Code neste workspace:'
        });
        if (!choice) {
            return;
        }
        if (choice.action === 'enterprise_init') {
            const terminal = vscode.window.createTerminal('Nimbus Code Enterprise Bootstrap');
            terminal.show();
            terminal.sendText('curl -fsSL https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/raw/main/bootstrap.sh | bash');
            vscode.window.showInformationMessage('🚀 Executando bootstrap oficial do Nimbus Code Enterprise no terminal integrado...');
        }
        else if (choice.action === 'community') {
            const rootFolder = vscode.workspace.workspaceFolders[0];
            const rootUri = rootFolder.uri;
            const constitutionUri = vscode.Uri.joinPath(rootUri, 'constitution.md');
            const specifyDirUri = vscode.Uri.joinPath(rootUri, '.specify');
            const templatesDirUri = vscode.Uri.joinPath(rootUri, '.specify', 'templates');
            try {
                // Solicitar opcionalmente dados para registro e suporte personalizado
                const userEmail = await vscode.window.showInputBox({
                    prompt: 'Opcional: Informe seu email corporativo para suporte da comunidade e atualizações:',
                    placeHolder: 'seu-email@empresa.com'
                });
                const userCompany = await vscode.window.showInputBox({
                    prompt: 'Opcional: Nome da sua empresa/organização:',
                    placeHolder: 'Empresa / Time'
                });
                await vscode.workspace.fs.createDirectory(templatesDirUri);
                const defaultConstitution = `# Constituição do Projeto (Nimbus Code Community Edition)\n\n## Princípios Não-Negociáveis\n1. **Especificação Antes do Código**: Crie spec.md e plan.md antes de implementar.\n2. **TDD**: Testes automatizados obrigatórios.\n3. **Segurança**: Jamais comite credenciais ou segredos.\n4. **Isolamento**: Altere somente arquivos do escopo da tarefa.\n`;
                await vscode.workspace.fs.writeFile(constitutionUri, Buffer.from(defaultConstitution, 'utf8'));
                const defaultSpec = `# Feature Specification: [Nome]\n\n**Slug:** \`[slug]\`\n\n## 1. Visão Geral\n[Descrição]\n\n## 2. Requisitos SMART\n- **S/M/A/R/T:** [Critérios]\n\n## 3. Cenários BDD\n- **Dado** ... **Quando** ... **Então** ...\n`;
                await vscode.workspace.fs.writeFile(vscode.Uri.joinPath(templatesDirUri, 'spec-template.md'), Buffer.from(defaultSpec, 'utf8'));
                // Enviar telemetria para registro do usuário/empresa
                await registerCommunityTelemetry(rootFolder.name, envCheck.remoteUrl || '', userEmail, undefined, userCompany);
                vscode.window.showInformationMessage('✅ Workspace inicializado com sucesso no modo Nimbus Code Community! Use o Copilot Chat para interagir com o @nimbus.');
            }
            catch (err) {
                vscode.window.showErrorMessage(`Falha ao criar arquivos do Nimbus Code: ${err?.message || err}`);
            }
        }
        else if (choice.action === 'enterprise_info') {
            const contactChoice = await vscode.window.showInformationMessage('🏢 Nimbus Code Enterprise VPN: inclui 18 agentes nativos com RACI, Catálogo Central de Harness Corporativo, API de Harvest para código legado (Brownfield) e Sanfona de Dev.', 'Abrir Site da VPN', 'Falar com Especialista');
            if (contactChoice === 'Abrir Site da VPN') {
                vscode.env.openExternal(vscode.Uri.parse('https://venhapranuvem.com.br'));
            }
            else if (contactChoice === 'Falar com Especialista') {
                vscode.env.openExternal(vscode.Uri.parse('mailto:contato@venhapranuvem.com.br?subject=Interesse%20no%20Nimbus%20Code%20Enterprise'));
            }
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.openSquad', async () => {
        const option = await vscode.window.showQuickPick([
            { label: '🌟 Inicializar Repositório', detail: 'Configurar Nimbus Code Community ou Conectar ao Enterprise VPN', command: 'nimbus.initRepository' },
            { label: '🚀 Orquestrador do Squad', detail: 'Chamar @nimbus para triagem geral (Bug/Fix, Nova Spec, Ideação)', query: '@nimbus conduzir processo de engenharia' },
            { label: '💡 Ideação & Validação de Hipótese', detail: 'Executar ciclo de assessment (/nc-assess-intake, /nc-assess-shape, /nc-assess-decide)', command: 'nimbus.ideation' },
            { label: '🐛 Triagem e Correção de Bug', detail: 'Executar fluxo de Bug/Fix (/nc-bug-assess, /nc-bug-fix, /nc-bug-test)', command: 'nimbus.bugFix' },
            { label: '📋 Criar Nova Especificação', detail: 'Executar /nc-spec (SMART + BDD)', command: 'nimbus.newSpec' },
            { label: '📐 Planejar Arquitetura Técnica', detail: 'Executar /nc-arch (ADRs + Grafos de Dependência)', command: 'nimbus.planArchitecture' },
            { label: '🧪 Gerar Estratégia de Testes', detail: 'Executar /nc-qa (Estratégia de QA e tasks.md [P])', command: 'nimbus.generateTasks' },
            { label: '🛠️ Executar Implementação Autônoma', detail: 'Executar /nc-builder (Implementar tasks.md sob isolamento)', command: 'nimbus.implementFeature' },
            { label: '🛡️ Auditar Segurança & DevSecOps', detail: 'Executar /nc-shield (Controles não-negociáveis, TLS e segredos)', command: 'nimbus.auditSecurity' },
            { label: '🔍 Verificar Status e Licença', detail: 'Checar modo DevX / Enterprise da VPN', command: 'nimbus.verifyHealth' }
        ], {
            placeHolder: 'Selecione uma ação do Squad Nimbus Code:'
        });
        if (option) {
            if (option.command) {
                await vscode.commands.executeCommand(option.command);
            }
            else if (option.query) {
                await triggerChatOrPrompt(option.query);
            }
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.ideation', async () => {
        const idea = await vscode.window.showInputBox({
            prompt: 'Descreva a ideia bruta ou hipótese a ser validada:',
            placeHolder: 'ex: Permitir login sem senha via Magic Link'
        });
        if (idea) {
            await triggerChatOrPrompt(`@nimbus /nc-assess-intake Validar e estruturar a seguinte ideia: ${idea}`);
        }
        else {
            await triggerChatOrPrompt('@nimbus iniciar ciclo de ideação e assessment');
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.bugFix', async () => {
        const bugDesc = await vscode.window.showInputBox({
            prompt: 'Descreva o comportamento inesperado ou cole o link/texto do bug:',
            placeHolder: 'ex: Erro 500 ao tentar renovar token JWT expirado'
        });
        if (bugDesc) {
            await triggerChatOrPrompt(`@nimbus /nc-bug-assess Avaliar e propor remediação para o bug: ${bugDesc}`);
        }
        else {
            await triggerChatOrPrompt('@nimbus iniciar triagem de bug');
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.newSpec', async () => {
        const featureName = await vscode.window.showInputBox({
            prompt: 'Informe o nome/slug da feature a ser especificada:',
            placeHolder: 'ex: user-authentication-jwt'
        });
        if (featureName) {
            await triggerChatOrPrompt(`@nimbus /nc-spec Criar especificação funcional para ${featureName}`);
        }
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.planArchitecture', async () => {
        await triggerChatOrPrompt('@nimbus /nc-arch Gerar plano de arquitetura técnica, grafos de dependência e ADRs');
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.generateTasks', async () => {
        await triggerChatOrPrompt('@nimbus /nc-qa Decompor em tasks.md com estratégia de testes e paralelismo [P]');
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.implementFeature', async () => {
        await triggerChatOrPrompt('@nimbus /nc-builder Executar implementação autônoma das tasks em tasks.md');
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.auditSecurity', async () => {
        await triggerChatOrPrompt('@nimbus /nc-shield Auditar segurança, segredos e conformidade DevSecOps');
    }));
    context.subscriptions.push(vscode.commands.registerCommand('nimbus.verifyHealth', () => {
        const statusMsg = mode === 'local_unrestricted'
            ? '✅ Nimbus Code: Modo Local (DevX Habilitado — Sem Bloqueio de Licença).'
            : '🔒 Nimbus Code: Modo Enterprise Conectado ao Entitlement da VPN.';
        vscode.window.showInformationMessage(statusMsg);
    }));
}
function deactivate() { }
//# sourceMappingURL=extension.js.map