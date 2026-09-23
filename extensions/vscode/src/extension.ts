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

  // Função auxiliar para abrir chat do Copilot com o prompt pronto
  async function triggerChatOrPrompt(queryText: string) {
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
    vscode.commands.registerCommand('nimbus.openSquad', async () => {
      const option = await vscode.window.showQuickPick([
        { label: '🚀 Orquestrador do Squad', detail: 'Chamar @nimbus para triagem (Bug/Fix, Nova Spec, Ideação)', query: '@nimbus orquestrar projeto' },
        { label: '📋 Criar Nova Especificação', detail: 'Executar /nc-spec (SMART + BDD)', query: '@nimbus /nc-spec ' },
        { label: '📐 Planejar Arquitetura Técnica', detail: 'Executar /nc-arch (ADRs + Grafos de Dependência)', query: '@nimbus /nc-arch ' },
        { label: '🧪 Gerar Estratégia de Testes', detail: 'Executar /nc-qa (Estratégia de QA e tasks.md [P])', query: '@nimbus /nc-qa ' },
        { label: '🛠️ Executar Implementação Autônoma', detail: 'Executar /nc-builder (Implementar tasks.md sob isolamento)', query: '@nimbus /nc-builder ' },
        { label: '🛡️ Auditar Segurança & DevSecOps', detail: 'Executar /nc-shield (Controles não-negociáveis e TLS)', query: '@nimbus /nc-shield ' },
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
    vscode.commands.registerCommand('nimbus.verifyHealth', () => {
      const statusMsg = mode === 'local_unrestricted'
        ? '✅ Nimbus Code: Modo Local (DevX Habilitado — Sem Bloqueio de Licença).'
        : '🔒 Nimbus Code: Modo Enterprise Conectado ao Entitlement da VPN.';
      vscode.window.showInformationMessage(statusMsg);
    })
  );
}

export function deactivate() {}

