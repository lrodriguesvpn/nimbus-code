# Constituição Corporativa de IA

## Propósito

Definir uma única política corporativa para todo uso de IA da empresa.

## Princípios

- Existe apenas uma constituição corporativa de IA.
- Os dados corporativos seguem os controles de acesso, retenção e auditoria já
  definidos pelos sistemas da empresa.
- Nenhuma ferramenta de IA cria uma política paralela.
- Toda decisão de exceção deve ser explícita e rastreável.

## Ferramentas oficiais

- **Microsoft Copilot** para produtividade e colaboração de negócio.
- **GitHub Enterprise Copilot** para engenharia e entrega de software.

## Escopo de aplicação

- Aplicável a qualquer agente ou assistente de IA da empresa.
- Aplicável a agentes criados no Microsoft 365.
- Aplicável a usos permitidos de Claude Enterprise e ChatGPT quando estes
  ainda forem necessários.

## Regras mínimas

- Cada agente tem owner humano identificado.
- Cada agente tem escopo de uso e audiência explícitos.
- Compartilhamento e publicação precisam seguir aprovação corporativa.
- O uso de dados respeita permissões já concedidas ao usuário.
- A constituição é revisada periodicamente quando surgirem novas ferramentas ou
  novos riscos.

## Política anti-Shadow IT para código

- Microsoft 365 Copilot e M365 Copilot CoWork **não são canais autorizados para
  gerar código de produção em larga escala**.
- Conteúdo de código gerado em CoWork com escopo maior que snippet/referência
  (ex.: blocos longos com centenas de linhas) deve ser tratado como rascunho
  não-oficial e não pode seguir para produção sem reentrada pelo fluxo oficial.
- O fluxo oficial de código é: repositório corporativo + branch + PR + revisão
  + rastreabilidade (GitHub Enterprise Copilot no contexto de engenharia).
- Toda entrega de código final deve ser versionada e revisada no processo de
  engenharia da empresa; não há exceção por conveniência da ferramenta.
- Tentativas de contornar esse fluxo (sideload de agente sem aprovação,
  publicação aberta, compartilhamento indiscriminado) são tratadas como risco de
  shadow IT e devem ser bloqueadas administrativamente.

## Exceções registradas (ferramentas de IA complementares)

- **TypeSafe/Jev** (skill `typesafe-ai`): adotado como ferramenta
  **complementar, opcional e experimental** para julgamentos tipados de baixo
  custo (roteamento, classificação, verificação) — nunca em substituição ao
  Copilot/GitHub Enterprise Copilot como motor de geração de código, e nunca
  em decisões S3/S4 sem revisão humana. Ver
  [ADR 0010](../adr/0010-adocao-experimental-typesafe-jev-para-julgamentos-tipados.md)
  e [oportunidades de uso no Nimbus Code](../comparisons/typesafe-jev-oportunidades-nimbus-code.md).

## Comandos Nimbus Code e Esquadrão Multiagente

Os comandos `/nc-*` e o esquadrão de 15 agentes `NC-*` (ex.: `/nc-spec`,
`/nc-arch`, `/nc-qa`, `/nc-builder`, etc.) constituem a camada de especialização
e governança institucional do NIMBUS CODE™, mantendo total interoperabilidade
com o motor base do Spec Kit (`speckit-*`). A matriz completa de mapeamento está
documentada em [nimbus-aliases.md](nimbus-aliases.md).
