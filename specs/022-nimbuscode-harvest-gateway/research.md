# Research: Nimbus Harvest Gateway — Conector Multicloud

## Contexto

Todas as decisões técnicas abaixo foram discutidas e confirmadas com o Dev
durante a sessão de planejamento (2026-08-24), antes deste plano ser escrito
— não há `NEEDS CLARIFICATION` pendente.

## Decisão 1 — Padrão de integração: Gateway compartilhado vs. integração por repositório

**Decisão**: Gateway HTTP compartilhado, único endpoint para toda a organização.

**Rationale**: `scripts/harvest-patterns.sh` já é shipado a todo projeto via o
preset `nimbus-code-standards`, mas exige um backend que nunca foi
construído. Se cada repositório satélite construísse seu próprio backend,
haveria duplicação de esforço de engenharia, nenhuma padronização de escolha
de modelo, e nenhuma visibilidade centralizada de custo — o oposto do
objetivo de reduzir custo de token que motiva o próprio Harvest (ver
`docs/ai-code-quality-and-observability.md`, seção 9).

**Alternatives considered**:
- Cada repositório satélite implementa seu próprio backend de IA: rejeitado
  por duplicar esforço e fragmentar observabilidade de custo.
- Usar diretamente a API de um provedor sem camada intermediária: rejeitado
  porque o contrato de `harvest-patterns.sh` (`{repo, stack, prompt,
  metadata}` → array de padrões) não corresponde ao formato nativo de
  nenhum provedor — sempre seria necessária uma camada de tradução em algum
  lugar; centralizá-la no Gateway evita reimplementar essa tradução em cada
  repositório.

## Decisão 2 — Padrão de conectores: Router + interface comum vs. 3 serviços separados

**Decisão**: Um único serviço com um `Connector Router` interno que seleciona,
por variável de ambiente (`HARVEST_LLM_PROVIDER`), qual conector concreto
(`AzureAIConnector`, `GoogleConnector`, `AWSBedrockConnector`) processa a
requisição — todos implementando a mesma interface (`LLMConnector.complete`).

**Rationale**: troca de provedor ou de modelo dentro do mesmo provedor vira
só uma variável de ambiente, sem exigir redeploy de código nem coordenar
mudança em nenhum repositório satélite (AC-5). Cada conector já usa, por
natureza, uma API unificada do próprio provedor (Azure AI Foundry, Vertex
AI, Bedrock Runtime) que já resolve múltiplos modelos por parâmetro — o
Router só precisa escolher QUAL cliente de SDK instanciar, não reimplementar
lógica de seleção de modelo dentro de cada nuvem.

**Alternatives considered**:
- Três serviços/deploys separados (um por nuvem): rejeitado por multiplicar
  esforço operacional (3 deploys, 3 URLs) sem benefício real, já que o
  contrato exposto para `harvest-patterns.sh` é idêntico nos três casos.
- Lógica de seleção de provedor no próprio `harvest-patterns.sh`: rejeitado
  porque violaria o requisito explícito de não alterar o script (FR-001) e
  vazaria decisão de infraestrutura de nuvem para dentro de um script que
  hoje é agnóstico a isso.

## Decisão 3 — Hospedagem: Azure Functions (Consumption) vs. alternativas

**Decisão**: Azure Functions, plano Consumption.

**Rationale**: volume de chamadas é baixo por design (Harvest é on-demand,
nunca automático/CI — ver constituição e `docs/harness/...`/`FR-011` do
SPEC-014 equivalente para Harvest). Um plano que escala a zero elimina custo
de infraestrutura ociosa, e a organização já tem presença operacional em
Azure (Azure DevOps, referências a Azure Policy/CAF na constituição de
plataforma), reduzindo a curva de aprendizado operacional.

**Alternatives considered**:
- AWS Lambda / Google Cloud Functions como hospedagem única: rejeitado por
  não haver motivo técnico para hospedar em uma nuvem só porque o Gateway
  suporta múltiplas nuvens **como destino** de inferência — a hospedagem do
  próprio Gateway é uma decisão independente de quais conectores ele expõe.
- Azure Container Apps: rejeitado para a v1 por exigir mais esforço
  operacional (gestão de container/imagem) sem benefício claro dado o baixo
  volume esperado; pode ser revisitado se o volume crescer.

## Decisão 4 — Linguagem/runtime: Python

**Decisão**: Python 3.11.

**Rationale**: os três SDKs relevantes (`openai` para Azure AI Foundry,
`google-genai`/`google-cloud-aiplatform` para Vertex AI/Gemini, `boto3` para
AWS Bedrock) têm suporte maduro e idiomático em Python, e o Azure Functions
Python Worker v2 tem suporte de primeira classe para funções HTTP simples
como esta.

**Alternatives considered**:
- TypeScript/Node.js: também viável (todos os 3 SDKs têm client Node), mas
  Python foi preferido por ser a linguagem já usada em scripts auxiliares
  deste ecossistema (`scripts/harvest-patterns.sh` já invoca blocos Python
  inline para parsing/payload).

## Decisão 5 — Ausência de SSO tradicional (ver também Security Gate do plan.md)

**Decisão**: autenticação machine-to-machine via `HARVEST_API_TOKEN`
(bearer token), sem fluxo de SSO/login humano.

**Rationale**: o único consumidor do endpoint é o próprio
`scripts/harvest-patterns.sh`, executado por um humano localmente ou por um
agente — nunca há uma sessão de usuário interativa contra o Gateway. SSO
tradicional (OIDC/SAML com IdP corporativo) não tem papel funcional aqui.

**Alternatives considered**:
- Exigir SSO mesmo assim, "por padrão": rejeitado por não ter nenhum ponto
  de login humano real para proteger — adicionaria complexidade sem
  benefício de segurança adicional. Documentado como item "Escapável via
  ADL" no Security Gate do `plan.md`, com justificativa explícita.

## Decisão 6 — Estratégia de release: `direct`

**Decisão**: deploy direto, sem feature flag/canary/blue-green.

**Rationale**: Harvest é uma ferramenta on-demand sem tráfego de produção
contínuo a proteger; rollback é trivial (esvaziar a variável de organização
`HARVEST_API_URL`, revertendo ao estado atual em que o Harvest já não
funciona). Ativação incremental por conector (Azure primeiro, depois Google
e AWS) já está coberta pela ordem de prioridade das User Stories, sem
necessidade de infraestrutura de flag adicional.

**Alternatives considered**:
- Feature flag por conector via OpenFeature: considerado, mas rejeitado
  como exigência formal desta v1 — a "ativação incremental" já é natural
  pela ordem de implementação das User Stories (US1 Azure → US2 Google → US3
  AWS), sem necessitar de um mecanismo de flag em runtime para algo que é
  decidido em tempo de deploy/configuração, não em tempo de execução por
  usuário/segmento.
