# Migração de Nome do Repositório — NIMBUS CODE

Este documento formaliza a separação entre os dois repositórios da iniciativa
NIMBUS CODE e serve como guia operacional para a troca do slug do repositório
base.

## 1. Diferença entre os repositórios

| Repositório | Tipo | Fonte de verdade para | Responsável principal |
|---|---|---|---|
| `nimbus-code-spec-kit-template` | template / foundation | bootstrap, presets, extensões, workflows, catálogos, templates e documentação operacional | arquitetura, padrões e automações |
| `nimbus-code` | produto / marketing | branding, naming comercial, storytelling, decks, páginas e GTM | produto, liderança e marketing |

### Regras

- O **repo template/foundation** pode ser citado pelo repo de produto, mas não o
  contrário como dependência operacional.
- O **repo de produto/marketing** não deve publicar catálogos, bootstrap ou
  templates consumidos por outros projetos.
- O **nome comercial** é **NIMBUS CODE™ AI Delivery System**.
- O **substrato técnico** continua sendo **GitHub Spec Kit**.
- Os nomes técnicos do modelo (`specify`, `plan`, `tasks`, `implement`,
  `converge`, `spec.md`, `plan.md`) **não mudam**.

## 2. O que muda com o rename

Troca-se o slug do repositório-base:

- **de:** `speckit-vpndev-standards`
- **para:** `nimbus-code-spec-kit-template`

Isso afeta:

1. URLs web do repositório
2. URLs raw usadas por bootstrap e templates
3. URLs de release assets usadas por catálogos
4. Caminhos locais em exemplos `--dev`
5. Referências profundas para documentação
6. Workflows/templates copiados para projetos consumidores

## 3. Inventário interno deste repositório

As referências foram consolidadas nas seguintes classes:

- `README.md`
- `bootstrap.sh`
- `presets/catalog.json`
- `extensions/catalog.json`
- `workflows/catalog.json`
- `bundles/catalog.json`
- manifests `preset.yml`, `bundle.yml`, `extension.yml`
- templates copiados para repositórios consumidores
- documentação operacional em `docs/`

## 4. Frentes da migração

### Frente A — repositório-fonte

Executar primeiro:

1. Renomear o repositório para `nimbus-code-spec-kit-template`
2. Publicar releases/catálogos já apontando para o novo slug
3. Atualizar bootstrap, templates, manifests e links absolutos
4. Atualizar a documentação institucional explicando a diferença entre os dois
   repositórios

### Frente B — repositórios consumidores

Executar após a Frente A estar validada:

1. Localizar todo uso do slug antigo na organização
2. Classificar por criticidade
3. Corrigir primeiro os repositórios com automação contínua
4. Corrigir depois os repositórios com dependência apenas documental

## 5. Classificação de criticidade para consumidores

| Nível | Critério | Exemplos |
|---|---|---|
| **Crítico** | depende de bootstrap, catálogos, release assets ou workflows sincronizados | `curl .../bootstrap.sh`, leitura de `catalog.json`, clone do repo para rodar scripts |
| **Médio** | copia templates ou links profundos para docs | `README-bundle-section`, templates de workflow, docs internas |
| **Baixo** | referência textual sem efeito operacional | menção ao nome do repo em apresentações, notas ou documentação auxiliar |

## 6. Checklist de atualização para outros repositórios

Em cada repositório consumidor, procurar e atualizar:

- `https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/...`
- `https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards`
- caminhos locais `./speckit-vpndev-standards/...`
- referências ao README/template deste repositório
- workflows que clonam o repo antigo para rodar scripts

## 7. Compatibilidade temporária

Durante a janela de transição:

- manter comunicação explícita de depreciação do slug antigo;
- monitorar quais projetos ainda dependem do caminho antigo;
- congelar a propagação para consumidores se bootstrap, catálogos ou workflows
  quebrarem;
- só continuar a migração em massa depois da validação do repositório-fonte.

## 8. Critério de sucesso

A migração estará concluída quando:

- o repositório-base estiver claramente posicionado como **template/foundation**;
- o repositório `nimbus-code` estiver claramente posicionado como
  **produto/marketing**;
- as referências internas deste repositório estiverem no novo slug;
- os repositórios consumidores tiverem migrado as referências operacionais;
- nenhum nome técnico do Spec Kit tiver sido substituído.

## 9. Execução prática (ordem recomendada)

### 9.1 Validar o repositório-fonte (este repo)

Rodar no root do repositório:

```bash
bash -n ./bootstrap.sh
jq empty ./presets/catalog.json
jq empty ./extensions/catalog.json
jq empty ./workflows/catalog.json
jq empty ./bundles/catalog.json
rg -n "speckit-vpndev-standards" .
```

Esperado:

- `bootstrap.sh` sem erro de sintaxe;
- todos os `catalog.json` válidos;
- nenhuma referência antiga operacional ativa (sobrando somente contexto histórico
  de "de → para" neste documento).

### 9.2 Varredura org-wide dos consumidores

Rodar:

```bash
./scripts/scan-org-rename-references.sh
```

O script lista cada hit da organização com:

- criticidade (`CRITICO`, `MEDIO`, `BAIXO`);
- repositório + arquivo;
- exatamente o que trocar (slug/URL antiga → nova).

## 10. O que precisa ser mudado manualmente nos repositórios consumidores

Para **cada ocorrência** que o script apontar:

1. Trocar slug antigo:
   - `speckit-vpndev-standards` → `nimbus-code-spec-kit-template`
2. Trocar URL raw:
   - `https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/...`
   - `https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template/...`
3. Trocar URL web:
   - `https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards`
   - `https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/nimbus-code-spec-kit-template`
4. Trocar caminhos locais:
   - `./speckit-vpndev-standards/...` → `./nimbus-code-spec-kit-template/...`

Prioridade:

1. **CRITICO**: bootstrap/catálogos/release assets/workflows;
2. **MEDIO**: templates e docs internas;
3. **BAIXO**: menções textuais sem efeito operacional.

## 11. Fluxo obrigatório de mudança (sem aprovação direta)

Mudança de padrão/política **não é aprovada direto em arquivo**.
Fluxo mínimo por repositório:

1. branch
2. commit
3. PR
4. revisão + aprovação (CODEOWNERS quando aplicável)
5. CI verde
6. merge

Executar em lotes pequenos:

- 1 PR por repositório consumidor;
- só avançar para o próximo lote depois que CI/merge do lote atual estiverem OK.
