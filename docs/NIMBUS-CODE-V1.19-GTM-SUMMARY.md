# Nimbus Code v1.19 — Resumo Executivo & Guia de Go-to-Market (GTM)

> **Documento de Apoio para o Time de Marketing & Vendas**  
> **Versão**: 1.19.0 (Dev Standards) & 0.5.0 (Platform Standards)  
> **Data**: Setembro/2026  
> **Classificação**: Interno / Material Base para Campanhas e Materiais Comerciais

---

## 1. O que é o Nimbus Code?

O **Nimbus Code** é a plataforma corporativa de **Engenharia de Software e Plataforma Acelerada por IA Agêntica** da Nimbus-Code. 

Construído sobre os fundamentos do *GitHub Spec Kit* (concebido no ecossistema MIT/GitHub) e evoluído para o contexto enterprise, o Nimbus Code transforma a IA generativa de um "mero autocompletar de código" em um **ciclo de engenharia governado, seguro e auditável** ponta a ponta.

### 💡 O Slogan / Tagline
> **"Da Intenção de Negócio à Produção: Engenharia Agêntica com Governança Não-Negociável."**

---

## 2. A Dor do Mercado vs. A Solução Nimbus Code

| Dor Tradicional com IA no Mercado | Como o Nimbus Code v1.19 Resolve |
|---|---|
| **Alucinação e Código Sem Contexto**: IAs geram código desconectado das regras de negócio e da arquitetura existente. | **Especificação Guiada (Spec-First)**: O agente só escreve código após a aprovação de especificações de negócio, planos de arquitetura e tarefas rastreáveis. |
| **Caixa-Preta de Custos**: Empresas não sabem quanto a IA realmente custa nem o esforço humano investido na correção de código gerado. | **Gestão de Custos Híbrida**: Rastreamento em tempo real de consumo de tokens de IA somado às horas humanas de revisão e refino via GitHub Projects. |
| **Quebra de Segurança e Compliance**: Código gerado viola LGPD, expõe segredos ou ignora controles corporativos de infraestrutura. | **DevSecOps & Compliance Gates Nativos**: Checagens automáticas de LGPD, segurança, TLS, cofre de segredos e branch protection em toda feature. |
| **Dificuldade em Projetos Legados (Brownfield)**: Ferramentas de IA funcionam bem em demos simples, mas falham em monólitos e microsserviços legados. | **Context-Aware Multi-Repo & Brownfield Engine**: Leitura profunda da base de código, mapeamento de grafos de dependência e herança de padrões históricos. |
| **Erros Repetitivos da IA**: Agentes cometem os mesmos erros de integração repetidamente. | **Harness Engineering & Playbooks de Sucesso**: Memória viva organizacional que impede erros já mapeados no passado e replica boas práticas comprovadas. |

---

## 3. Os 5 Pilares Fundamentais do Nimbus Code v1.19

### 🏛️ 1. Governança e Perfis Especializados
- **Perfil Dev Standards (`--repo-type dev_standards`)**: Focado em desenvolvimento de aplicações, APIs, microsserviços, qualidade de código e esteiras CI/CD.
- **Perfil Platform Standards (`--repo-type platform`)**: Focado em engenharia de plataforma, Landing Zones multi-cloud (Azure/AWS), conformidade contínua (CMDB DSC) e infraestrutura como código (Terraform).
- **Setup em 1 Comando**: Provisionamento automatizado e idempotente via `bootstrap.sh`.

### 🔍 2. Ciclo de Vida Estruturado (Specify → Plan → Tasks → Implement → Converge)
1. **Entrevista de Descoberta (`/speckit-interview`)**: Conduz o alinhamento com o stakeholder cobrindo Negócio, Infraestrutura, Segurança e LGPD.
2. **Especificação Clara (`/speckit-specify`)**: Define os requisitos funcionais e critérios de aceitação mensuráveis (sem suposições).
3. **Plano de Arquitetura (`/speckit-plan`)**: Desenha módulos, integrações e valida os gates de segurança antes de codar.
4. **Decomposição em Tarefas (`/speckit-tasks` & `/speckit-taskstoissues`)**: Gera tarefas ordenadas com criação automática da hierarquia Agile no GitHub (Epic → Feature → User Story → Task).
5. **Implementação & Convergência (`/speckit-implement` & `/speckit-converge`)**: Executa sob isolamento estrito de sessão e audita se 100% do escopo foi entregue, fechando lacunas remanescentes.

### 🧠 3. Memória Organizacional Viva (Harness & Playbooks)
- **Harness Engineering**: Um catálogo ativo (`harness-catalog.yaml`) que alerta o desenvolvedor e o agente sobre armadilhas e falhas conhecidas antes da execução.
- **Playbook de Sucesso**: Registro e replicação imediata de arquiteturas e padrões testados que entregaram alto valor.

### 📊 4. Visibilidade Executiva & Métricas DORA Nativas
- Coleta e auditoria automatizada dos 4 indicadores-chave de engenharia:
  - **Deployment Frequency (Frequência de Deploy)**
  - **Lead Time for Changes (Tempo de Entrega)**
  - **Change Failure Rate (Taxa de Falha em Mudanças)**
  - **Mean Time to Recovery - MTTR (Tempo Médio de Recuperação)**
- Painel de Gestão unificado no GitHub Project V2 com rastreamento de prioridades P0 a P3.

### 💰 5. Rastreamento Financeiro & ROI Transparente
- Cálculo do custo real por feature (`Tokens Consumidos × Custo por Milhão + Horas Humanas × Valor/Hora`).
- Comparador multi-modelo de LLMs (Claude, GPT, Gemini) para otimização de custo/benefício por complexidade (S0 a S4).

---

## 4. Matriz de Valor por Persona (Para Argumentação Comercial & MKT)

| Persona | O que ela mais valoriza no Nimbus Code? | Pitch de Impacto |
|---|---|---|
| **CIO / CTO** | Previsibilidade, redução de risco de segurança, governança de custos e conformidade LGPD. | *"Acelere o time-to-market em até 3x sem transformar sua TI em uma fábrica desgovernada de código não auditado."* |
| **Head of Engineering / Squad Leads** | Produtividade com qualidade, onboarding relâmpago de desenvolvedores e métricas DORA claras. | *"Seus squads entregam mais com menos retrabalho, orientados por um framework que padroniza boas práticas em todos os repositórios."* |
| **Arquiteto de Software / Enterprise Architect** | Decisões registradas em ADRs, grafos de módulos vivos e aderência a padrões multi-repo. | *"Chega de arquiteturas esquecidas no Confluence: a arquitetura do Nimbus Code é viva, versionada no Git e validada em tempo de compilação."* |
| **Líder de Segurança & DevSecOps** | Zero segredos expostos, revisão humana obrigatória em itens críticos (S4) e branch protection garantida. | *"Segurança 'by design' e não 'post-mortem'. Nenhum código crítico vai para produção sem passar pelos gates de DevSecOps."* |
| **Desenvolvedor / Engenheiro de Software** | Fim do retrabalho com prompts vagos, isolamento claro de tarefas e automação de burocracias. | *"Menos tempo escrevendo boilerplate e preenchendo cards; mais tempo focado em resolver os problemas de negócio que importam."* |

---

## 5. Sugestões de Peças e Conteúdos para a Campanha de GTM

### 🎬 A. Vídeo Demonstração / Teaser (1 a 2 minutos)
- **Cena 1**: O problema — Desenvolvedor perdido em um repo legado tentando usar IA sem contexto.
- **Cena 2**: A solução — Um único comando `bootstrap.sh` inicializa o repositório com o Nimbus Code v1.19.
- **Cena 3**: O fluxo — Execução do `/speckit-interview` gerando a spec, plan e as issues no GitHub Project automaticamente.
- **Cena 4**: O resultado — Código entregue, métricas DORA verdes e custo da feature exibido com precisão.

### 📄 B. One-Pager Comercial / Fact Sheet
- Diagrama do ciclo de vida (Specify → Plan → Tasks → Implement → Converge).
- Box de destaque com os diferenciais: *Harness Engineering*, *Multi-Repo Context-Aware* e *Hybrid Cost Tracking*.
- Depoimento/Métrica de impacto: *"Redução de 40% no tempo de refinamento técnico e 0% de retrabalho em arquiteturas S3/S4."*

### 📱 C. Posts de Lançamento (LinkedIn & Tech Blog)
- **Headline**: *Lançamos o Nimbus Code v1.19: A engenharia agêntica que as grandes empresas precisavam.*
- **Ganchos**:
  1. Por que autocompletar de código não escala sem especificação formal.
  2. Como controlar o custo real de IA + horas humanas em um único painel.
  3. O conceito de Harness Engineering: ensinando a IA a nunca cometer o mesmo erro duas vezes.

---

## 6. Glossário Rápido para o Time de Comunicação

- **Spec-Kit**: Metodologia onde a especificação detalhada guia a inteligência artificial.
- **Brownfield**: Sistemas e repositórios existentes que já possuem histórico e código legado.
- **Greenfield**: Novos projetos criados do zero.
- **Harness**: Mecanismo de salvaguarda que impede que a IA repita falhas conhecidas.
- **S0 a S4**: Régua de complexidade técnica que define o modelo de IA ideal e a necessidade de revisão humana.
- **DORA Metrics**: Métricas padrão da indústria para medir performance e maturidade de engenharia de software.
