# Governança M365

## Objetivo

Aplicar a constituição corporativa de IA a qualquer agente criado no
ecossistema Microsoft 365.

## Canais cobertos

- Microsoft 365 Copilot
- M365 Copilot CoWork
- Agentes publicados para times ou áreas

## Regras de governança

- Agentes respeitam permissões existentes do usuário.
- Agentes não recebem novos privilégios por conta própria.
- O owner do agente é responsável por escopo, publicação e manutenção.
- Compartilhamento pode ser restrito por usuários, grupos ou desligado.
- Dados acessados por agentes continuam sujeitos a DLP, retenção e auditoria.

## Controles operacionais no portal M365

> Caminhos administrativos principais (Microsoft 365 admin center):
>
> - **Copilot > Agents**: inventário, enable/disable, assign, block, remove.
> - **Copilot > Settings > Data access > Agents**: política de compartilhamento
>   de agentes (todos, grupos específicos, ninguém).

Aplicação mínima recomendada:

1. Restringir compartilhamento para grupos específicos (não "todos").
2. Bloquear/publicar somente agentes aprovados com owner definido.
3. Revisar periodicamente inventário de agentes ativos e remover agentes órfãos.
4. Usar logs/auditoria para monitorar uso fora da política.

## Como fazer o M365 Copilot usar esta política

Não existe configuração global única para "apontar URL do GitHub e obrigar todo
Copilot a ler". O padrão técnico recomendado é:

1. Publicar a constituição em um local oficial do tenant (SharePoint).
2. Manter este repositório como fonte de versionamento e aprovação da política.
3. Em cada agente M365 (Agent Builder/Copilot Studio), adicionar o documento da
   constituição como fonte de conhecimento e instrução obrigatória.
4. Restringir quem pode criar/publicar agentes para evitar versões paralelas da
   política.

Veja o passo a passo em
[`m365-policy-centralization.md`](m365-policy-centralization.md).

## Regra anti-Shadow IT para CoWork

- M365 Copilot CoWork não é canal oficial para gerar código de produção em
  larga escala.
- Para reduzir shadow IT, trate geração extensa de código em CoWork como uso
  não-compliance e redirecione para fluxo oficial em GitHub Enterprise Copilot.
- Como controle administrativo, combine:
  - restrição de compartilhamento/publicação de agentes,
  - monitoramento por auditoria,
  - política explícita de engenharia com PR obrigatório.

## Perguntas que sempre precisam estar respondidas

- Quem é o owner?
- Qual é a audiência?
- Quais dados o agente pode usar?
- O agente foi aprovado para publicação?
- O uso está alinhado à constituição corporativa?

## Notas

Este guia documenta governança, não enforcement técnico. A execução continua
dependendo dos controles oficiais do Microsoft 365.
