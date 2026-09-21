# Intake de Assessment — Agente de Prototipação de Telas

## Identificação

| Campo | Valor |
|---|---|
| **Slug** | `agente-prototipacao-telas` |
| **Data** | 2026-09-21 |
| **Origem** | Ideia informada diretamente pelo solicitante via `/nc-assess-intake` |
| **Tipo de entrada** | Texto livre |
| **Status** | Intake capturado — aguardando pesquisa |

## Ideia bruta

Validar a ideia de criar um agente que ajude na prototipação de telas antes de
elas serem codificadas. O agente deverá apoiar a exploração visual e de
experiência, permitindo validar uma direção de interface antes do início da
implementação.

## Problema ou oportunidade percebida

Decisões de interface podem chegar ao desenvolvimento antes de serem
visualizadas, discutidas e validadas. Um agente de prototipação poderia reduzir
retrabalho, tornar a conversa entre negócio, design e engenharia mais concreta
e antecipar problemas de fluxo ou entendimento.

Esta é uma hipótese inicial, não uma conclusão de valor ou viabilidade.

## Público potencial

- Product Owners e analistas de negócio;
- designers e responsáveis por UX/UI;
- desenvolvedores e tech leads;
- stakeholders que precisam revisar uma experiência antes da codificação.

## Resultado desejado inicialmente

Produzir protótipos navegáveis ou representações visuais suficientemente claras
para discussão e validação, mantendo rastreabilidade com a ideia ou feature que
será posteriormente especificada e implementada.

## Limites conhecidos

- A ideia trata de prototipação anterior à codificação.
- Ainda não está definido se o resultado deve ser wireframe, mockup de alta
  fidelidade, protótipo navegável ou código descartável.
- Ainda não está definido se o agente deve apenas gerar alternativas ou também
  conduzir validações com usuários/stakeholders.
- Não há decisão sobre ferramenta de renderização, formato de saída ou
  integração com o fluxo de especificação.

## Encaixe nos dois fluxos do Nimbus Code

A capacidade deve ser considerada nos dois fluxos, sem forçar toda demanda a
passar por um único caminho.

### Fluxo A — Entrada pela Ideação / Assessment

Indicado quando ainda existe uma oportunidade ou problema pouco definido e não há
uma feature formal aprovada.

1. `/nc-assess-intake` captura a ideia inicial.
2. `/nc-assess-research` investiga demanda, usuários, alternativas e
   restrições.
3. `/nc-assess-define` formaliza problema, público, dores e métricas.
4. `/nc-assess-shape` compara opções de solução e decide se a prototipação é
   necessária.
5. O agente de prototipação, em conjunto com `nc-designer`, gera e itera
   wireframes, mockups ou protótipos navegáveis.
6. A decisão de avanço (`/nc-assess-decide`) usa o protótipo como evidência.
7. Se aprovado, o resultado é entregue ao fluxo de Spec Formal por meio de uma
   nova `interview.md` ou de um contexto de entrada referenciando os artefatos
   visuais.

**Resultado do fluxo A:** ideia validada, opção de experiência escolhida e
evidências prontas para iniciar uma especificação formal.

### Fluxo B — Entrada direta pela Spec Formal

Indicado quando o problema, a feature ou a demanda já foi aprovada e o objetivo
é especificar uma solução conhecida, mesmo que a interface ainda precise ser
explorada.

1. `/nc-intake` conduz a entrevista de descoberta nos blocos obrigatórios.
2. `/nc-spec` identifica se a feature possui uma superfície Web ou outra
   experiência visual que exige prototipação.
3. O agente de prototipação, com `nc-designer`, cria as alternativas visuais a
   partir da entrevista, requisitos conhecidos ou cenários de uso.
4. Stakeholders validam o protótipo durante a elaboração da `spec.md`.
5. A `spec.md` incorpora as decisões visuais, fluxos, estados, acessibilidade e
   critérios de aceitação.
6. O processo segue para `/nc-critic`, arquitetura, plano, tasks e
   implementação.

**Resultado do fluxo B:** uma `spec.md` mais precisa, com protótipo validado
como artefato de apoio e rastreabilidade entre experiência e requisitos.

### Regra de decisão entre os fluxos

- Se a necessidade ainda é uma hipótese ou oportunidade: iniciar pelo **Fluxo
  A — Ideação / Assessment**.
- Se a feature já tem objetivo, patrocinador e escopo suficientes para
  especificação: iniciar pelo **Fluxo B — Spec Formal**.
- Se uma ideia começou no Fluxo A e foi aprovada, ela deve fazer handoff para a
  Spec Formal; não deve permanecer indefinidamente apenas como protótipo.
- Se uma feature entrou diretamente no Fluxo B, a ausência de pesquisa de
  assessment não é uma falha; o protótipo funciona como instrumento de
  descoberta e validação dentro da especificação.

O agente deve ser tratado como uma capacidade reutilizável de prototipação,
acionável nos dois fluxos, e não como substituto de `/nc-assess-*`, `/nc-intake`
ou `/nc-spec`.

## Perguntas em aberto

- Qual tipo de protótipo entrega valor mínimo: wireframe, mockup, protótipo
  navegável ou outro?
- Quem aprova o protótipo e quais evidências determinam que ele está pronto para
  virar especificação?
- O agente deverá trabalhar a partir de entrevista, descrição textual, issue,
  requisitos existentes ou todos esses formatos?
- Como serão preservados acessibilidade, identidade visual e padrões oficiais
  de design?
- O protótipo deverá ser versionado junto da feature? Em qual formato?
- Que métricas demonstrariam redução de retrabalho ou melhoria na validação?
- Existem dados pessoais, fluxos sensíveis ou informações de clientes nas telas
  que exigiriam controles adicionais?
- O agente deve gerar somente artefatos visuais ou também uma ponte rastreável
  para `spec.md`, cenários BDD e critérios de aceitação?

## Próximo handoff

Recomenda-se executar `/nc-assess-research` para investigar demanda, práticas
de prototipação, alternativas existentes, restrições de acessibilidade e o
melhor ponto do processo Nimbus Code. Depois, o fluxo pode seguir para
`/nc-assess-define` e `/nc-assess-shape` antes de qualquer decisão de
implementação.
