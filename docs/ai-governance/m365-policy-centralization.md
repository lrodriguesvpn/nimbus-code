# Centralização da Política no M365 Copilot

## Objetivo

Explicar tecnicamente onde configurar no portal M365 para que agentes/copilots
usem a constituição corporativa desta organização.

## Ponto importante

Hoje, o M365 Copilot não oferece um switch único de tenant para "ler sempre um
arquivo do GitHub". A centralização é feita por:

- política administrativa no tenant,
- publicação da constituição em fonte oficial do M365,
- vínculo dessa fonte nos agentes aprovados.

## Passo 1 — Publicar a constituição em fonte oficial do tenant

1. Criar uma página ou documento no SharePoint corporativo com conteúdo da
   política canônica.
2. Definir owners e permissões somente para grupos autorizados.
3. Manter o conteúdo sincronizado com
   [`corporate-constitution.md`](corporate-constitution.md).

## Passo 2 — Definir governança no Microsoft 365 admin center

No **Microsoft 365 admin center**:

1. Acessar **Copilot > Settings > Data access > Agents**.
2. Em sharing policy, preferir **Specific users or groups** (evitar "All users").
3. Definir quem pode usar/compartilhar agentes no escopo corporativo.

Depois, em **Copilot > Agents**:

1. Revisar inventário de agentes existentes.
2. Bloquear/remover agentes fora de padrão.
3. Manter somente agentes aprovados com owner.

## Passo 3 — Amarrar a constituição nos agentes

Para cada agente criado em Agent Builder/Copilot Studio:

1. Adicionar a política do SharePoint como knowledge source.
2. Incluir instrução explícita de sistema: "seguir constituição corporativa".
3. Publicar apenas após aprovação do owner de governança.

## Passo 4 — Reduzir Shadow IT no CoWork (código extenso)

Como não há controle universal por "número de linhas" no prompt:

- Definir regra corporativa: CoWork não é canal de código de produção.
- Exigir fluxo oficial para código final (repo + PR + revisão).
- Monitorar uso com auditoria e tratar violações como não-conformidade.
- Restringir criação/publicação de agentes a grupos aprovados.

## Evidência mínima para fechamento de issue operacional

- Registrar no issue a **URL completa do SharePoint** onde a constituição foi publicada.
- Anexar evidência da execução (print das telas ou checklist textual dos caminhos
  administrativos alterados).
- Declarar dependências bloqueadoras no issue antes de iniciar (quando houver).

## Checklist de implementação

- [ ] Constituição publicada no SharePoint oficial
- [ ] URL completa do SharePoint registrada no issue de execução
- [ ] Caminho **Copilot > Settings > Data access > Agents** configurado para grupos específicos
- [ ] Inventário em **Copilot > Agents** revisado e limpo
- [ ] Agentes aprovados apontando para a política canônica
- [ ] Regra anti-shadow-IT formalizada em engenharia e governança
- [ ] Evidência anexada no issue (print ou checklist textual)
