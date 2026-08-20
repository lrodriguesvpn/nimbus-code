# Fixture: bootstrap-target

Diretório mínimo e seguro para copiar/duplicar durante testes do `bootstrap.sh`
sem tocar em um repositório real. Os testes desta feature inicializam um repo git
isolado a partir desta pasta e executam o bootstrap com stubs locais de
`specify`.
