# Tasks: Nimbus Code Dual-Distribution (Lite Community vs Enterprise VPN)

**Feature Slug:** `030-nimbus-code-open-core-dual-distribution`  
**Status:** Completed  

---

## Tarefas de Implementação

- [x] **T01 [P] - Criar Preset Comunitário (`presets/nimbus-code-community/`)**
  - Criar templates básicos de `spec.md`, `plan.md`, `tasks.md` e `constitution.md`.
  - Criar `README.md` do preset comunitário explicando o fluxo simplificado.

- [x] **T02 [P] - Atualizar a Extensão VS Code com Inicialização Interativa**
  - Adicionar comando `nimbus.initRepository` em `package.json` e `src/extension.ts`.
  - Implementar lógica que cria scaffold comunitário local no workspace.
  - Oferecer opção de "Community Edition (Gratuito)" e "Enterprise Edition (VPN)".

- [x] **T03 - Atualizar README Público e Documentação de Distribuição**
  - Atualizar `docs/public/README.md` / `README.md` público com a matriz comparativa:
    - Nimbus Code Lite (Gratuito / BSL 1.1) vs Nimbus Code Enterprise (VPN).
    - Destaque para serviços VPN: Sanfona de Desenvolvimento, Harvest de Brownfield e Harness Corporativo.
    - Canais de contato para contratação da VPN.

- [x] **T04 - Atualizar Scripts de Exportação & Sincronização Pública**
  - Ajustar `scripts/export-public-repo.sh` e `scripts/sync-public-repo.sh` para incluir o preset comunitário e nova documentação.

- [x] **T05 - Compilar, Testar e Empacotar a Extensão VSIX**
  - Rodar `npm run compile` e `npm run package` em `extensions/vscode`.
  - Testar instalação local da extensão.

- [x] **T06 - Publicar em `develop` e Sincronizar com GitHub Público**
  - Realizar commit das alterações.
  - Executar sincronização com `github.com/lrodriguesvpn/nimbus-code` via `scripts/sync-public-repo.sh`.
