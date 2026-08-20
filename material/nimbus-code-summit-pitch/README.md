# NIMBUS CODE — Material de Apresentação (Summit)

Material comercial/institucional para apresentação de produto (ex.: Microsoft
Summit). Não faz parte do fluxo Nimbus-Code (spec-kit) nem é consumido por
nenhum script/skill — é conteúdo de marketing, mantido aqui apenas para
versionamento e histórico.

## Arquivos

- `nimbus-code-resumo-executivo.md` — resumo comercial completo: problemas
  que o NIMBUS CODE resolve, os 10 pilares, prova real (dados extraídos ao
  vivo do repositório), público-alvo e diferencial competitivo.
- `NIMBUS-CODE-Apresentacao.pptx` — apresentação de 4 slides com gráficos
  nativos editáveis, focada em demonstrar o produto de forma funcional
  ("da ideia ao código, com IA supervisionada por humano"), sem jargão
  técnico interno.
- `build_deck.py` — script Python (`python-pptx`) usado para gerar o PPTX.
  Reexecutável (`python build_deck.py`) para regenerar o arquivo após editar
  textos/cores no próprio script.

## Como atualizar

1. Editar `build_deck.py` (cores, textos, gráficos).
2. Rodar `pip install python-pptx` (se necessário) e `python build_deck.py`.
3. O arquivo `NIMBUS-CODE-Apresentacao.pptx` é sobrescrito no mesmo diretório.
