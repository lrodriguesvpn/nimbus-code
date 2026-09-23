# Implementation Plan: Nimbus Code Dual-Distribution (Lite Community vs Enterprise VPN)

**Feature Slug:** `030-nimbus-code-open-core-dual-distribution`  
**Status:** In Progress  

---

## 1. Classificação de Complexidade

- **Nível:** S3 (Multi-módulo, empacotamento de distribuição, extensão VS Code e esteira de sync segura)
- **Modelo:** GPT-5.4 / Claude Sonnet
- **Bounded Context:** `governance-distribution`
- **Padrão Reutilizado:** Sim (`distribution`, `governance`)
- **Estimativa de Tokens:** ~15.000 – 25.000 tokens

---

## 2. Arquitetura da Solução

1. **Preset Comunitário (`presets/nimbus-code-community/`)**:
   - Fornece templates base: `spec-template.md`, `plan-template.md`, `tasks-template.md`, `constitution.md`.
   - Inclui `@nimbus` Lite sem referências a módulos internos restritos.
2. **Comando de Inicialização na Extensão VS Code (`nimbus.initRepository`)**:
   - Inspeciona o workspace ativo.
   - Permite criar o scaffold comunitário em 1 clique.
   - Exibe informações sobre como habilitar o modo Enterprise através de contratação ou token da VPN.
3. **Documentação Pública no Repositório GitHub**:
   - `README.md` público reformulado destacando:
     - O que é o Nimbus Code Lite (Open-Core / BSL 1.1).
     - O que é o Nimbus Code Enterprise (VPN).
     - Como contratar a VPN (Sanfona de Dev, Harvest Brownfield, Harness Corporativo).
4. **Pipeline de Exportação & Sincronização (`scripts/export-public-repo.sh` e `scripts/sync-public-repo.sh`)**:
   - Exporta a extensão, preset community, documentação pública e scripts auxiliares limpos de credenciais e IP privado.

---

## 3. Gates Obrigatórios

### Security & DevSecOps Gate
- [x] **Não-Negociável - Segredos:** Nenhuma chave, credencial ou token incluído nos pacotes ou repositório público.
- [x] **Não-Negociável - Isolamento de IP:** Módulos de Harvest proprietário e Catálogo de Harness Corporativo mantidos exclusivamente no repositório privado.
- [x] **Não-Negociável - Branch Protegida & PR:** Mudanças integradas via PR e testes automatizados.

### Qualidade de Código & Observabilidade Gate
- [x] Código da extensão TypeScript compilado sem erros e com testes de build (`npm run package`).
- [x] Scripts Bash validados com permissão de execução.

### Harness Gate
- [x] Padrão `HRN-0009` (verificação de ciclo de vida do PR) e isolamento de escopo respeitados.
