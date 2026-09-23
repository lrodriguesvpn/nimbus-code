import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
  const outputChannel = vscode.window.createOutputChannel('Nimbus Code');
  outputChannel.appendLine('[Nimbus Code] Extensão ativada com sucesso.');

  const config = vscode.workspace.getConfiguration('nimbus');
  const mode = config.get<string>('mode', 'local_unrestricted');

  if (mode === 'local_unrestricted') {
    outputChannel.appendLine('[Nimbus Code] Executando em modo LOCAL IRRESTRITO (Teste & DevX ativo).');
  }

  // 0. Status Bar Item (Indicador visual sempre visível e clicável)
  const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
  statusBarItem.text = '$(rocket) Nimbus Code';
  statusBarItem.tooltip = 'Nimbus Code: Clique para abrir o menu do Squad de Agentes';
  statusBarItem.command = 'nimbus.openSquad';
  statusBarItem.show();
  context.subscriptions.push(statusBarItem);

  // Função auxiliar para validar se há workspace aberto ou oferecer abertura/clonagem de repo
  async function ensureWorkspace(): Promise<boolean> {
    const folders = vscode.workspace.workspaceFolders;
    if (folders && folders.length > 0) {
      return true;
    }

    const choice = await vscode.window.showWarningMessage(
      '⚠️ O Nimbus Code requer uma pasta ou repositório Git aberto para gerenciar especificações e artefatos.',
      'Abrir Pasta Local',
      'Clonar Repositório Git',
      'Continuar Mesmo Assim'
    );

    if (choice === 'Abrir Pasta Local') {
      await vscode.commands.executeCommand('vscode.openFolder');
      return false;
    } else if (choice === 'Clonar Repositório Git') {
      const repoUrl = await vscode.window.showInputBox({
        prompt: 'Informe a URL do repositório Git que deseja clonar e abrir:',
        placeHolder: 'https://github.com/usuario/meu-projeto.git'
      });
      if (repoUrl) {
        await vscode.commands.executeCommand('git.clone', repoUrl);
      }
      return false;
    } else if (choice === 'Continuar Mesmo Assim') {
      return true;
    }

    return false;
  }

  // Função auxiliar para abrir chat do Copilot com o prompt pronto
  async function triggerChatOrPrompt(queryText: string) {
    const hasWorkspace = await ensureWorkspace();
    if (!hasWorkspace) {
      return;
    }

    try {
      await vscode.commands.executeCommand('workbench.action.chat.open', { query: queryText });
    } catch {
      try {
        await vscode.commands.executeCommand('workbench.action.quickchat.open', { query: queryText });
      } catch {
        vscode.window.showInformationMessage(`Nimbus Code: Execute no Chat do Copilot: ${queryText}`);
      }
    }
  }

  // 1. Comandos do Command Palette
  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.initRepository', async () => {
      const hasWorkspace = await ensureWorkspace();
      if (!hasWorkspace) {
        return;
      }

      const choice = await vscode.window.showQuickPick([
        {
          label: '🟢 Inicializar Nimbus Code Community (Gratuito)',
          detail: 'Configura o fluxo Spec-Driven Development (SDD), constitution.md e templates locais.',
          action: 'community'
        },
        {
          label: '🔵 Obter Nimbus Code Enterprise (Venha Pra Nuvem)',
          detail: 'Desbloqueia 18 agentes nativos, Harness Corporativo, Harvest Brownfield e Sanfona de Dev.',
          action: 'enterprise'
        }
      ], {
        placeHolder: 'Escolha como deseja inicializar o Nimbus Code neste workspace:'
      });

      if (!choice) {
        return;
      }

      if (choice.action === 'community') {
        const rootUri = vscode.workspace.workspaceFolders![0].uri;
        const constitutionUri = vscode.Uri.joinPath(rootUri, 'constitution.md');
        const specifyDirUri = vscode.Uri.joinPath(rootUri, '.specify');
        const templatesDirUri = vscode.Uri.joinPath(rootUri, '.specify', 'templates');

        try {
          await vscode.workspace.fs.createDirectory(templatesDirUri);

          const defaultConstitution = `# Constituição do Projeto (Nimbus Code Community Edition)\n\n## Princípios Não-Negociáveis\n1. **Especificação Antes do Código**: Crie spec.md e plan.md antes de implementar.\n2. **TDD**: Testes automatizados obrigatórios.\n3. **Segurança**: Jamais comite credenciais ou segredos.\n4. **Isolamento**: Altere somente arquivos do escopo da tarefa.\n`;
          await vscode.workspace.fs.writeFile(constitutionUri, Buffer.from(defaultConstitution, 'utf8'));

          const defaultSpec = `# Feature Specification: [Nome]\n\n**Slug:** \`[slug]\`\n\n## 1. Visão Geral\n[Descrição]\n\n## 2. Requisitos SMART\n- **S/M/A/R/T:** [Critérios]\n\n## 3. Cenários BDD\n- **Dado** ... **Quando** ... **Então** ...\n`;
          await vscode.workspace.fs.writeFile(vscode.Uri.joinPath(templatesDirUri, 'spec-template.md'), Buffer.from(defaultSpec, 'utf8'));

          vscode.window.showInformationMessage('✅ Workspace inicializado com sucesso no modo Nimbus Code Community! Use o Copilot Chat para interagir com o @nimbus.');
        } catch (err: any) {
          vscode.window.showErrorMessage(`Falha ao criar arquivos do Nimbus Code: ${err?.message || err}`);
        }
      } else if (choice.action === 'enterprise') {
        const contactChoice = await vscode.window.showInformationMessage(
          '🏢 Nimbus Code Enterprise VPN: inclui 18 agentes nativos com RACI, Catálogo Central de Harness Corporativo, API de Harvest para código legado (Brownfield) e Sanfona de Dev.',
          'Abrir Site da VPN',
          'Falar com Especialista'
        );
        if (contactChoice === 'Abrir Site da VPN') {
          vscode.env.openExternal(vscode.Uri.parse('https://venhapranuven.com.br'));
        } else if (contactChoice === 'Falar com Especialista') {
          vscode.env.openExternal(vscode.Uri.parse('mailto:contato@venhapranuven.com.br?subject=Interesse%20no%20Nimbus%20Code%20Enterprise'));
        }
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.openSquad', async () => {
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
        } else if (option.query) {
          await triggerChatOrPrompt(option.query);
        }
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.ideation', async () => {
      const idea = await vscode.window.showInputBox({
        prompt: 'Descreva a ideia bruta ou hipótese a ser validada:',
        placeHolder: 'ex: Permitir login sem senha via Magic Link'
      });
      if (idea) {
        await triggerChatOrPrompt(`@nimbus /nc-assess-intake Validar e estruturar a seguinte ideia: ${idea}`);
      } else {
        await triggerChatOrPrompt('@nimbus iniciar ciclo de ideação e assessment');
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.bugFix', async () => {
      const bugDesc = await vscode.window.showInputBox({
        prompt: 'Descreva o comportamento inesperado ou cole o link/texto do bug:',
        placeHolder: 'ex: Erro 500 ao tentar renovar token JWT expirado'
      });
      if (bugDesc) {
        await triggerChatOrPrompt(`@nimbus /nc-bug-assess Avaliar e propor remediação para o bug: ${bugDesc}`);
      } else {
        await triggerChatOrPrompt('@nimbus iniciar triagem de bug');
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.newSpec', async () => {
      const featureName = await vscode.window.showInputBox({
        prompt: 'Informe o nome/slug da feature a ser especificada:',
        placeHolder: 'ex: user-authentication-jwt'
      });
      if (featureName) {
        await triggerChatOrPrompt(`@nimbus /nc-spec Criar especificação funcional para ${featureName}`);
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.planArchitecture', async () => {
      await triggerChatOrPrompt('@nimbus /nc-arch Gerar plano de arquitetura técnica, grafos de dependência e ADRs');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.generateTasks', async () => {
      await triggerChatOrPrompt('@nimbus /nc-qa Decompor em tasks.md com estratégia de testes e paralelismo [P]');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.implementFeature', async () => {
      await triggerChatOrPrompt('@nimbus /nc-builder Executar implementação autônoma das tasks em tasks.md');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.auditSecurity', async () => {
      await triggerChatOrPrompt('@nimbus /nc-shield Auditar segurança, segredos e conformidade DevSecOps');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('nimbus.verifyHealth', () => {
      const statusMsg = mode === 'local_unrestricted'
        ? '✅ Nimbus Code: Modo Local (DevX Habilitado — Sem Bloqueio de Licença).'
        : '🔒 Nimbus Code: Modo Enterprise Conectado ao Entitlement da VPN.';
      vscode.window.showInformationMessage(statusMsg);
    })
  );
}

export function deactivate() {}

