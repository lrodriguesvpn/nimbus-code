# Research: Governança de Repos Satélite e Intake Greenfield MultiRepo

## Objective

Resolver as decisões de processo necessárias para que o bootstrap do Nimbus Code
faça a entrada correta de projetos greenfield, preserve o fluxo brownfield já
existente e formalize a relação entre repo central e repositórios satélite.

## Decisions

### 1) Greenfield vs brownfield deve ser decidido pela presença de código de aplicação relevante

**Decision**: tratar como greenfield o repositório que ainda não possui código de
aplicação relevante; repositórios contendo apenas README, licença, arquivos de
setup, workflows vazios ou esqueleto mínimo não devem ser promovidos
automaticamente a brownfield real. Como regra operacional, contam como código
relevante diretórios ou arquivos que representem implementação real do produto
(`src/`, `app/`, `packages/`, `services/`, `frontend/`, `backend/`, testes de
aplicação e manifests de build/runtime já ligados a código). Não contam,
sozinhos, `README`, `LICENSE`, `.gitignore`, workflows, templates, scripts de
setup e pastas vazias.

**Rationale**: a pergunta do usuário não é apenas “o repo está vazio?”, e sim se
o produto já tem legado suficiente para exigir o fluxo brownfield.

**Alternatives considered**:
- Perguntar sempre manualmente sem qualquer orientação prévia
- Classificar brownfield somente porque o repositório não está vazio
- Ignorar a classificação e mandar todo mundo para o mesmo fluxo

### 2) A decisão mono vs multirepo precisa de justificativa obrigatória

**Decision**: o fluxo greenfield deve registrar o motivo da escolha entre
monorepo e multirepo como parte explícita do intake, em formato mínimo legível:
motivo principal, trade-off esperado e papel/responsável que confirmou a
decisão. O registro deve ser persistido em `.specify/feature.json` no objeto
`topology_decision` para manter rastreabilidade operacional.

**Rationale**: a decisão estrutural impacta ownership, board, bootstrap,
roteamento de tasks e futura decomposição do produto. Sem justificativa, a
topologia vira opinião oral e não decisão rastreável.

**Alternatives considered**:
- Deixar a decisão implícita pela primeira implementação
- Perguntar mono vs multirepo, mas sem pedir motivo
- Padronizar tudo como multirepo por default

### 3) A sugestão de domínios satélite deve acontecer após a primeira spec estrutural

**Decision**: para greenfield multirepo, a sugestão inicial de domínios satélite
entra após a primeira spec estrutural do produto, não antes de existir um mínimo
de entendimento do problema. O bootstrap registra a decisão multirepo e faz o
handoff explícito para esse passo posterior, mas não tenta materializar a
topologia completa cedo demais; a baseline FRONT/BACK/DESIGN/DATA/JOBS é
apenas recomendação inicial, adaptável com justificativa + ownership.

**Rationale**: sugerir satélites cedo demais força particionamento artificial. A
primeira spec dá contexto suficiente para decidir se a baseline recomendada faz
sentido e como adaptá-la.

**Alternatives considered**:
- Criar satélites antes da primeira spec
- Nunca sugerir baseline de domínios
- Obrigar uma taxonomia única independente do produto

### 4) FRONT, BACK, DESIGN, DATA e JOBS são baseline recomendada, não taxonomia rígida

**Decision**: usar FRONT, BACK, DESIGN, DATA e JOBS como baseline sugerida para
greenfield multirepo, permitindo domínios alternativos ou complementares com
justificativa explícita e ownership mínimo identificável (time, papel ou repo
responsável por cada domínio).

**Rationale**: a organização ganha aceleração e linguagem comum sem transformar
um ponto de partida em regra universal para todo produto.

**Alternatives considered**:
- Lista fixa obrigatória para todos os produtos
- Nenhuma sugestão padrão
- Sugestão livre sem qualquer baseline organizacional

### 5) O repo central continua sendo a única fonte de verdade para specs

**Decision**: `spec.md`, `plan.md`, `tasks.md`, grafos, pesquisas, contratos e
checklists permanecem apenas no repo central do produto; satélites recebem
código, PRs e tasks roteadas.

**Rationale**: isso preserva rastreabilidade única, reduz drift e mantém clara a
separação entre governança do produto e execução por domínio.

**Alternatives considered**:
- Permitir `specs/` locais nos satélites
- Duplicar parte da spec no satélite “por conveniência”
- Mover toda a governança para o primeiro satélite criado

### 6) O alinhamento central → satélite deve reaproveitar o mecanismo oficial de update

**Decision**: o satélite deve permanecer alinhado ao bundle oficial pelo mesmo
mecanismo contínuo de atualização já adotado pelo template, sempre via PR
revisado.

**Rationale**: criar um segundo fluxo de sincronização aumentaria custo
operacional e risco de divergência silenciosa entre repositórios.

**Alternatives considered**:
- Atualização manual ad hoc em cada satélite
- Sincronização automática sem PR
- Um novo mecanismo paralelo só para satélites
