# Feature Specification: Nimbus Code Dual-Distribution (Lite Community vs Enterprise VPN)

**Feature Slug:** `030-nimbus-code-open-core-dual-distribution`  
**Status:** In Progress  
**Autor:** Nimbus Code Squad / VPN  
**Complexidade:** S3  

---

## 1. Visão Geral & Problema

O **Nimbus Code** evoluiu como um framework robusto de Engenharia de Software Orientada a Especificação (SDD) e governança multi-agente dentro da Venha Pra Nuvem (VPN). Para expandir o alcance da tecnologia, atrair desenvolvedores e posicionar a VPN como referência em desenvolvimento agentico, estabelece-se a estratégia **Dual-Package (Open-Core)**:
1. **Nimbus Code Lite (Community Edition)**: Versão aberta (BSL 1.1) focada no desenvolvedor individual, com fluxo ágil de Spec-Driven Development, templates públicos e extensão para VS Code.
2. **Nimbus Code Enterprise (VPN Edition)**: Plataforma corporativa completa com 18 agentes nativos, Catálogo Central de Harness Corporativo, Gateway de Harvest de código para projetos brownfield, esteiras de governança S0–S4, segurança DevSecOps estrita e serviços de expansão técnica ("Sanfona de Dev") prestados pela VPN.

---

## 2. Requisitos SMART

- **S (Específico):** Criar um preset público `presets/nimbus-code-community/`, atualizar a extensão VS Code com inicialização interativa (`nimbus.initRepository`) e documentar no repositório público a matriz comparativa e os canais de contratação da VPN.
- **M (Mensurável):** 100% dos repositórios sem inicialização prévia conseguem inicializar o ambiente comunitário via extensão em < 5 segundos; o repositório público não contém segredos nem códigos restritos da VPN.
- **A (Atingível):** Reutiliza a base existente de scripts e extensão VS Code já validada nas fases anteriores.
- **R (Relevante):** Protege a propriedade intelectual da VPN enquanto maximiza o funil de adoção de novos clientes.
- **T (Temporal):** Especificação, implementação e publicação concluídas no ciclo atual.

---

## 3. Matriz de Diferenciação de Produto

| Capacidade | 🟢 Nimbus Code Community (Lite) | 🔵 Nimbus Code Enterprise (VPN) |
|---|---|---|
| **Público Alvo** | Devs individuais, estudantes, testes locais | Times de engenharia, CTOs, Enterprise |
| **Licença** | BSL 1.1 (Gratuito para dev/testes) | Comercial / Contrato com VPN |
| **Extensão VS Code** | Inclusa com comandos rápidos | Inclusa com comandos rápidos |
| **Inicializador** | `nimbus.initRepository` (Preset Community) | `bootstrap.sh --enterprise` (Squad Completo) |
| **Orquestrador `@nimbus`** | Triagem Lite (Bug, Spec, Ideação básica) | Squad Completo de 18 Agentes Nativos |
| **Harness Engineering** | Catálogo local vazio | **Catálogo Central Corporativo com sinc VPN** |
| **Harvest de Legado** | ❌ Não incluído | **API de Harvest & Ingestão Brownfield** |
| **Sanfona de Dev (Consultoria)** | ❌ Suporte via comunidade | **Alocação de Esquadrão e Suporte VPN** |

---

## 4. Cenários BDD (Behavior-Driven Development)

### Cenário 1: Inicialização de Repositório Comunitário via Extensão
- **Dado** que um desenvolvedor abre uma pasta vazia ou repositório sem Nimbus no VS Code
- **Quando** executa o comando `Nimbus: Initialize Repository`
- **E** seleciona a opção "Community Edition (Gratuito)"
- **Então** a extensão cria os arquivos `.specify/` e `presets/nimbus-code-community/` com templates básicos
- **E** exibe mensagem de sucesso com convite para conhecer os recursos Enterprise da VPN.

### Cenário 2: Exibição da Matriz Comparativa no Repositório Público
- **Dado** que um usuário acessa o repositório público `github.com/lrodriguesvpn/nimbus-code`
- **Quando** visualiza o `README.md`
- **Então** encontra a explicação clara do Nimbus Code Lite vs Nimbus Code Enterprise
- **E** vê os links e contatos para contratação dos serviços de Harvest Brownfield, Harness Corporativo e Sanfona de Desenvolvimento da VPN.

### Cenário 3: Proteção de Propriedade Intelectual na Exportação
- **Dado** que a esteira de sincronização pública é executada
- **Quando** os arquivos são exportados
- **Então** o script garante que segredos, catálogos fechados e specs internas da VPN não sejam copiados para o repositório público.
