# test_AC5_openfeature_mode_toggle

## Objetivo
Validar AC-5: toggles de modo usam OpenFeature e suportam caminhos ON/OFF com kill switch.

## Cenários
1. Flag OFF -> fluxo segue baseline anterior.
2. Flag ON em segmento piloto -> classificação por política nova.
3. Acionar kill switch -> retorno imediato ao baseline.

## Asserções
- Resolução de flag ocorre via abstração OpenFeature.
- Caminhos ON/OFF exercitados e documentados.
- Evento de kill switch registrado com timestamp e responsável.

