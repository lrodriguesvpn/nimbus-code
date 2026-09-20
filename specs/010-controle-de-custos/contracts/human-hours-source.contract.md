# Contract: GitHub Project Human Hours

O coletor lê o campo numérico `Horas Humanas` do item do GitHub Project. Campo
ausente ou sem valor produz o estado `human_hours_missing` e nunca vira zero.
Valor numérico é associado à feature com o identificador do item e timestamp de
leitura. Correções geram novo `CostRecord` com referência ao anterior.

