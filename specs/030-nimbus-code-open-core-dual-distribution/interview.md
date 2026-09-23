# Entrevista de Descoberta — Nimbus Code Dual-Distribution (Lite Community vs Enterprise VPN)

## 1. Bloco de Negócio
- **Objetivo Primário**: Disponibilizar uma versão pública/community do Nimbus Code ("Nimbus Code Lite") sob modelo Open-Core (BSL 1.1) para tração de mercado, adoção de desenvolvedores e geração de leads, mantendo o ecossistema corporativo avançado ("Nimbus Code Enterprise") restrito aos clientes e projetos da Venha Pra Nuvem (VPN).
- **Proposta de Valor da VPN**:
  - *Versão Community (Gratuita / BSL 1.1)*: Fornece o fluxo básico de Spec-Driven Development (SDD), comandos essenciais, templates públicos e extensão VS Code para desenvolvedores individuais e testes locais.
  - *Versão Enterprise (Comercial VPN)*: Desbloqueia o squad completo de 18 agentes nativos com auditoria RACI, Catálogo Central de Harness Corporativo com aprendizado contínuo, Gateway de Harvest de código legado para projetos brownfield, esteiras de governança S0–S4, segurança DevSecOps estrita e o modelo de "Sanfona de Desenvolvimento" (alocação sob demanda da equipe especializada da VPN).
- **Público Impactado**: CTOs, Tech Leads, Desenvolvedores e Empresas que buscam acelerar o ciclo de software com agentes de IA mantendo governança.

## 2. Bloco de Infraestrutura & Distribuição
- **Canais de Distribuição**:
  - Repositório Público no GitHub (`lrodriguesvpn/nimbus-code`).
  - Extensão VS Code (`.vsix` distribuível e futuramente Marketplace).
  - Repositório Privado no GHE da VPN com a esteira completa e histórico de engenharia.
- **Isolamento de Código**:
  - O repositório público conterá apenas a extensão, o preset `nimbus-code-community`, templates básicos e a documentação comparativa.
  - A propriedade intelectual avançada da VPN (Harness corporativo interno, regras proprietárias de Harvest, histórico de specs corporativas) permanece protegida no GHE e não é exportada.

## 3. Bloco de Segurança
- **Scan de Credenciais e Segredos**: Todas as exportações e sincronizações para o repositório público passam obrigatoriamente por verificação de segurança (gitleaks / secret scanning).
- **Sem Quebra de Compatibilidade**: O workflow interno e a estrutura de desenvolvimento dos engenheiros da VPN continuam 100% inalterados e compatíveis com as versões anteriores.

## 4. Bloco LGPD & Compliance
- Não há armazenamento de dados pessoais ou código proprietário de clientes no pacote comunitário.
- Modelo de privacidade BYO-LLM (Bring Your Own LLM) onde chaves e modelos são geridos pelo próprio usuário no VS Code.
