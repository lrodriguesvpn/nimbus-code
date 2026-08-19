# Platform Governance

Runtime operacional que alimenta o preset de plataforma com:

- SSO corporativo central;
- descoberta multicloud;
- CMDB orientado a IA;
- baselines de seguranca/compliance;
- compostor de DSC versionado;
- validacao advisory de Terraform.

## Uso rapido

```bash
cd platform-governance
./bootstrap.sh
node src/cli/main.js init --providers azure,aws --tenant tenant-1
node src/cli/main.js validate
npm test
```

`init` define escopo 1:N de provedores (um ou mais). `validate` reutiliza esse escopo salvo.

## Estrutura

- `src/` - servicos e contratos de runtime consumidos pela constituição do preset
- `tests/` - testes de contrato, integracao e smoke
- `docs/` - guias operacionais
- `.github/workflows/` - CI, release e graph guard
