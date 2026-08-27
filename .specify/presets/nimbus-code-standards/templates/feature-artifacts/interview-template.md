# Modelo de Entrevista de Descoberta — `<feature-slug>`

<!--
  Guia de entrevista para a fase de DESCOBERTA (antes de escrever o spec.md).
  Usado hoje por um humano (BA/ADE) conduzindo a conversa com o cliente/solicitante;
  desenhado para no futuro ser conduzido pelo NIMBUS AGENT via Microsoft Teams,
  gravando o transcript e preenchendo este mesmo formato.

  Referenciado por: .github/skills/speckit-specify/SKILL.md (checagem de cobertura
  mínima antes de finalizar o spec.md — ver seção "Cobertura da Entrevista de
  Descoberta" nesse SKILL). Roadmap de condução automatizada: ver
  specs/018-nimbus-agent-intake/spec.md (User Story "Conduzir entrevista de
  descoberta via Teams").

  Localização quando preenchido: specs/<feature-slug>/interview.md
-->

## Como usar este modelo

**Regra de ouro: esta entrevista existe para descobrir O QUE o cliente precisa
e POR QUE — nunca o COMO técnico será construído.** Se a conversa começar a
discutir tecnologia, framework, banco de dados ou arquitetura, anote como nota
lateral (não bloqueia a entrevista) e redirecione para o próximo bloco — o
"como" é decidido depois, no `/speckit-plan`, não aqui.

Não é um formulário de compliance para ser lido item a item sem contexto. Os
4 blocos abaixo podem ser conduzidos em qualquer ordem, de forma conversacional
— o objetivo é sair da reunião com todas as perguntas **obrigatórias**
respondidas (ou explicitamente marcadas `N/A — motivo`), não seguir um roteiro
rígido. Leva ~20–30 minutos numa conversa fluida.

**Nunca deixar uma pergunta obrigatória em branco silenciosamente.** Se o
respondente não souber, registre `[NEEDS CLARIFICATION: <o que falta>]` — isso
alimenta diretamente o `spec.md` gerado a partir desta entrevista.

---

## Cabeçalho

| Campo | Valor |
|---|---|
| **Data** | [YYYY-MM-DD] |
| **Solicitante/Cliente** | [nome/área] |
| **Facilitador** | [nome humano, ou "Nimbus Agent (Teams)"] |
| **Canal** | [presencial / Teams / assíncrono (formulário)] |
| **Feature slug (se já souber)** | [kebab-case, ou "a definir"] |

---

## Bloco 1 — Negócio (o quê e por quê) — **obrigatório**

*O coração da entrevista. Sem isso, não há spec possível.*

1. Qual problema ou necessidade você está tentando resolver? Para quem?
2. Como isso é feito hoje (se já existe um jeito manual ou alternativo)? *(descreva o processo atual, não como o novo sistema deve ser construído)*
3. O que "pronto" significa para você — como saberemos que funcionou?
4. Quem usa isso no dia a dia (perfis/papéis, não nomes de sistema)?
5. O que **definitivamente não** faz parte deste pedido agora (fora de escopo)?
6. Existe prazo ou evento que torna isso urgente?
7. Quem dá o aceite final (aprovação de que está correto)?

---

## Bloco 2 — Infraestrutura — **obrigatório, mas curto**

*Não é sobre desenhar a arquitetura — é sobre restrições e contexto que o Dev/agente precisa saber antes de propor o "como".*

1. Onde isso vai rodar/ser hospedado? *(nuvem já usada pela empresa, on-premise, SaaS de terceiro — se não souber, tudo bem, registrar "a definir em plan.md")*
2. Já existe um padrão, bounded context ou repositório de referência que essa solução deve seguir? *(ver `docs/bounded-contexts.yaml` se este projeto usa MultiRepo)*
3. Quem ou o quê vai acessar isso? *(usuários internos, parceiros externos, público, outro sistema/integração)*
4. Existe expectativa de volume (poucos usuários internos vs. escala alta/pública)?
5. Depende de integração com algum sistema já existente? Qual?

---

## Bloco 3 — Segurança — **obrigatório, mas curto**

1. Este sistema expõe alguma informação sensível ou crítica para o negócio?
2. Quem pode e quem não pode acessar (perfis de autorização, mesmo que a granularidade fina venha depois)?
3. Existe exigência de autenticação corporativa (SSO/AD) ou pode usar um padrão mais simples?
4. Há necessidade de auditoria/trilha de "quem fez o quê"?

---

## Bloco 4 — LGPD / Proteção de Dados — **obrigatório, mas curto**

1. Este pedido envolve dado pessoal (nome, e-mail, CPF, dado de saúde, localização, etc.)?
2. Se sim: de quem são esses dados — funcionário, cliente final, terceiro?
3. Qual a base legal para tratar esse dado? *(execução de contrato, consentimento, obrigação legal, legítimo interesse — se não souber, registrar como pendência para jurídico/DPO, não adivinhar)*
4. Esses dados têm prazo de retenção definido, ou existe pedido de exclusão a considerar?
5. Esse dado sai da organização (parceiro, fornecedor terceiro, nuvem fora do país)?

> Se a resposta ao item 1 for claramente "não" (nenhum dado pessoal envolvido),
> marque os itens 2–5 como `N/A — sem dado pessoal identificado` e siga em
> frente. Não force perguntas de LGPD quando não há dado pessoal em jogo — isso
> é burocracia sem valor.

---

## Encerramento

*Leia de volta um resumo do que foi entendido para o solicitante confirmar
antes de encerrar a reunião.*

- **Resumo em 3–5 linhas**: [o que foi entendido]
- **Pendências / [NEEDS CLARIFICATION]**: [lista — cada uma vira um marcador no spec.md]
- **Responsável por validar o spec.md gerado**: [nome]

---

## Checklist de Cobertura Mínima

*Usado por quem conduz a entrevista (humano ou Nimbus Agent) para autoavaliar
se a entrevista está completa antes de encerrar. Também é o contrato que o
`/speckit-specify` valida contra o input/transcript recebido — ver
`.github/skills/speckit-specify/SKILL.md`.*

- [ ] Objetivo de negócio (o quê e por quê) registrado
- [ ] Critério de sucesso/pronto definido
- [ ] Perfis de usuário identificados
- [ ] Escopo fora (o que não é) explicitado
- [ ] Infraestrutura: local de hospedagem ou padrão de referência indicado (ou "a definir")
- [ ] Infraestrutura: quem acessa identificado
- [ ] Segurança: sensibilidade/exposição indicada
- [ ] Segurança: perfis de autorização indicados
- [ ] LGPD: presença ou ausência de dado pessoal indicada
- [ ] LGPD: base legal indicada (ou marcada como pendência para jurídico/DPO)
- [ ] Toda pendência sem resposta está listada explicitamente como `[NEEDS CLARIFICATION]`

> Se qualquer item acima estiver ausente (não apenas resumido) no input recebido
> pelo `/speckit-specify`, trate como candidato a `[NEEDS CLARIFICATION]`,
> respeitando o limite de 3 marcadores e a prioridade: escopo de negócio >
> segurança/LGPD > infraestrutura > detalhe técnico. Nunca inventar resposta de
> segurança, infraestrutura ou LGPD silenciosamente.
