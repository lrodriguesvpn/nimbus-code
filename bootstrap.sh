#!/usr/bin/env bash
# Bootstrap: aplica o bundle vpndev-project-bundle num repositório novo ou existente.
#
# Uso:
#   curl -fsSL https://raw.venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards/main/bootstrap.sh | bash
# ou, com o repo já clonado localmente:
#   ./bootstrap.sh --local /caminho/para/speckit-vpndev-standards
#
# Este script existe porque, hoje, o bundle ainda não está publicado num catálogo
# (specify preset/extension/workflow catalogs) — ver "Publicação e Catálogo" no
# README.md raiz. Enquanto isso, o bootstrap usa `--dev`/paths locais diretamente.
# Quando o catálogo estiver publicado, este script pode ser trocado por:
#   specify bundle install vpndev-project-bundle --integration copilot
set -euo pipefail

STANDARDS_REPO="https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/speckit-vpndev-standards"
LOCAL_PATH=""
INTEGRATION="${SPECKIT_INTEGRATION_DEFAULT:-copilot}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      LOCAL_PATH="$2"
      shift 2
      ;;
    --integration)
      INTEGRATION="$2"
      shift 2
      ;;
    *)
      echo "Argumento desconhecido: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v specify >/dev/null 2>&1; then
  echo "❌ 'specify' CLI não encontrado. Instale primeiro: https://github.com/github/spec-kit#-get-started" >&2
  exit 1
fi

WORKDIR="$(pwd)"

if [[ -z "$LOCAL_PATH" ]]; then
  TMP_CLONE="$(mktemp -d)"
  trap 'rm -rf "$TMP_CLONE"' EXIT
  echo "→ Clonando $STANDARDS_REPO..."
  git clone --depth 1 "$STANDARDS_REPO" "$TMP_CLONE" >/dev/null
  LOCAL_PATH="$TMP_CLONE"
fi

echo "→ Inicializando projeto Spec Kit em $WORKDIR (integração: $INTEGRATION)..."
specify init --here --integration "$INTEGRATION" --force

echo "→ Instalando preset vpndev-standards..."
specify preset add --dev "$LOCAL_PATH/presets/vpndev-standards" --priority 5 \
  || echo "  (preset já instalado — pulei; use 'specify preset remove vpndev-standards' antes para reinstalar)"

echo "→ Instalando extensão vpndev-backlog-sync..."
specify extension add --dev "$LOCAL_PATH/extensions/vpndev-backlog-sync" \
  || echo "  (extensão já instalada — pulei; use 'specify extension remove vpndev-backlog-sync' antes para reinstalar)"

echo "→ Instalando workflow vpndev-full-cycle..."
specify workflow add "$LOCAL_PATH/workflows/vpndev-full-cycle" \
  || echo "  (workflow já instalado — pulei; use 'specify workflow remove vpndev-full-cycle' antes para reinstalar)"

echo "→ Instalando GitHub Action de verificação de atualização (Spec Kit + bundle VPN Dev)..."
UPDATE_CHECK_SRC="$LOCAL_PATH/templates/workflows/update-speckit-and-bundle.yml"
if [[ -f "$UPDATE_CHECK_SRC" ]]; then
  mkdir -p "$WORKDIR/.github/workflows"
  cp "$UPDATE_CHECK_SRC" "$WORKDIR/.github/workflows/update-speckit-and-bundle.yml"
  echo "  ✅ .github/workflows/update-speckit-and-bundle.yml instalado."
  echo "  ℹ Roda semanalmente + sob demanda; nunca aplica atualização sozinho, só abre/atualiza"
  echo "    uma issue de aviso. Requer o secret VPNDEV_STANDARDS_READ_TOKEN (PAT de qualquer"
  echo "    membro da organização venha-pra-nuvem) — configure em Settings → Secrets and"
  echo "    variables → Actions deste repositório. Ver 'Versão do Bundle em uso' no README."
else
  echo "  ⚠ Template update-speckit-and-bundle.yml não encontrado em $UPDATE_CHECK_SRC"
fi

echo ""
echo "→ Instalando GitHub Action que garante o GitHub Project do repositório..."
ENSURE_PROJECT_SRC="$LOCAL_PATH/templates/workflows/ensure-github-project.yml"
if [[ -f "$ENSURE_PROJECT_SRC" ]]; then
  mkdir -p "$WORKDIR/.github/workflows"
  cp "$ENSURE_PROJECT_SRC" "$WORKDIR/.github/workflows/ensure-github-project.yml"
  echo "  ✅ .github/workflows/ensure-github-project.yml instalado."
  echo "  ℹ Roda semanalmente + sob demanda; recria o GitHub Project (views + campos"
  echo "    'Horas Humanas'/'Oportunidade D365') se ele não existir mais — garante que"
  echo "    este repositório sempre tenha o Project, mesmo que o passo automático abaixo"
  echo "    tenha sido pulado (ex.: gh CLI indisponível na máquina de quem rodou o"
  echo "    bootstrap). Requer os secrets VPNDEV_PROJECT_TOKEN (PAT com escopos"
  echo "    repo+project) e VPNDEV_STANDARDS_READ_TOKEN — configure em Settings →"
  echo "    Secrets and variables → Actions deste repositório."
else
  echo "  ⚠ Template ensure-github-project.yml não encontrado em $ENSURE_PROJECT_SRC"
fi

echo ""
echo "ℹ Workflows OPT-IN (copie manualmente quando os pré-requisitos existirem):"
echo "  • templates/workflows/add-to-pmo-project.yml — conecta este repo ao Portfólio"
echo "    PMO (1x por organização, ver scripts/setup-pmo-org-project.sh)."
echo "  • templates/workflows/sync-priority-field.yml — mantém o campo nativo"
echo "    \"Priority\" sincronizado com o label priority:* em qualquer GitHub Project"
echo "    ao qual a issue/PR pertença (por-repositório e/ou Portfólio PMO). Sem"
echo "    edição manual após copiar. Ambos requerem o secret ADD_TO_PROJECT_PAT."

echo ""
echo "→ Instalando doc de perfis de custo humano (Júnior/Pleno/Sênior)..."
COST_PROFILES_SRC="$LOCAL_PATH/presets/vpndev-standards/templates/cost-profiles-and-rates.md"
if [[ -f "$COST_PROFILES_SRC" ]]; then
  mkdir -p "$WORKDIR/docs"
  if [[ -f "$WORKDIR/docs/cost-profiles-and-rates.md" ]]; then
    echo "  ℹ docs/cost-profiles-and-rates.md já existe — pulei (não sobrescrevo customização local)."
  else
    cp "$COST_PROFILES_SRC" "$WORKDIR/docs/cost-profiles-and-rates.md"
    echo "  ✅ docs/cost-profiles-and-rates.md instalado (taxas padrão: Júnior R\$40/Pleno"
    echo "     R\$60/Sênior R\$90 por hora — ajuste livremente para o seu projeto)."
  fi
else
  echo "  ⚠ Template cost-profiles-and-rates.md não encontrado em $COST_PROFILES_SRC"
fi

echo ""
echo "→ Instalando catálogo de reuso (docs/reuse-catalog.yaml)..."
REUSE_CATALOG_SRC="$LOCAL_PATH/presets/vpndev-standards/templates/reuse-catalog.yaml"
if [[ -f "$REUSE_CATALOG_SRC" ]]; then
  mkdir -p "$WORKDIR/docs"
  if [[ -f "$WORKDIR/docs/reuse-catalog.yaml" ]]; then
    echo "  ℹ docs/reuse-catalog.yaml já existe — pulei (não sobrescrevo customização local)."
  else
    cp "$REUSE_CATALOG_SRC" "$WORKDIR/docs/reuse-catalog.yaml"
    echo "  ✅ docs/reuse-catalog.yaml instalado (vazio — preencha conforme features"
    echo "     introduzirem padrões reaproveitáveis; ver ai-code-quality-and-observability.md"
    echo "     seção 9)."
  fi
else
  echo "  ⚠ Template reuse-catalog.yaml não encontrado em $REUSE_CATALOG_SRC"
fi

echo ""
echo "→ Instalando instruções do Copilot (.github/copilot-instructions.md)..."
COPILOT_INSTRUCTIONS_SRC="$LOCAL_PATH/presets/vpndev-standards/templates/project-root/copilot-instructions.md"
if [[ -f "$COPILOT_INSTRUCTIONS_SRC" ]]; then
  mkdir -p "$WORKDIR/.github"
  if [[ -f "$WORKDIR/.github/copilot-instructions.md" ]]; then
    echo "  ℹ .github/copilot-instructions.md já existe — pulei (não sobrescrevo customização local)."
  else
    cp "$COPILOT_INSTRUCTIONS_SRC" "$WORKDIR/.github/copilot-instructions.md"
    echo "  ✅ .github/copilot-instructions.md instalado — preencha os placeholders"
    echo "     (<project-name>, <org>/<repo>, stack) e mantenha atualizado a cada"
    echo "     mudança de arquitetura."
  fi
else
  echo "  ⚠ Template copilot-instructions.md não encontrado em $COPILOT_INSTRUCTIONS_SRC"
fi

BUNDLE_VERSION="$(grep -A4 '^bundle:' "$LOCAL_PATH/bundles/vpndev-project-bundle/bundle.yml" | grep -E '^\s*version:' | head -1 | sed -E 's/.*"([0-9.]+)".*/\1/')"
echo ""
echo "✅ Bundle vpndev-project-bundle v${BUNDLE_VERSION} aplicado com sucesso."
echo "   Registre a versão instalada no README do projeto (ver seção 'Bundle VPN Dev' do template de README)."
echo ""

# Criar GitHub Project com as views padrão (opcional, requer GH CLI autenticado)
if command -v gh >/dev/null 2>&1; then
  echo ""
  echo "→ Configurando GitHub Project V2 com views padrão..."
  
  # Detectar repo owner/name a partir do git remote
  if GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null); then
    # Extrai owner/repo de URLs como:
    # - https://venha-pra-nuvem.ghe.com/venha-pra-nuvem/meu-repo.git
    # - git@venha-pra-nuvem.ghe.com:venha-pra-nuvem/meu-repo.git
    #
    # Usa expansão de parâmetros em vez de regex com quantificador "lazy"
    # (`+?`) — o bash padrão do macOS (3.2, por licenciamento GPL) usa ERE
    # puro, que NÃO suporta quantificadores lazy; `[^/]+?` casava de forma
    # imprevisível (ou não casava) e, quando casava, incluía o sufixo
    # ".git" no nome do repo. Isso fazia esta detecção falhar silenciosamente
    # (cai no "⚠ Não consegui extrair...") em praticamente todo bootstrap
    # real, já que qualquer remote clonado normalmente termina em ".git".
    REPO_PATH="$GIT_REMOTE"
    if [[ "$REPO_PATH" == git@* ]]; then
      REPO_PATH="${REPO_PATH#*:}"
    else
      REPO_PATH="${REPO_PATH#*://}"
      REPO_PATH="${REPO_PATH#*/}"
    fi
    REPO_PATH="${REPO_PATH%.git}"
    if [[ -n "$REPO_PATH" && "$REPO_PATH" == */* ]]; then
      REPO_OWNER="${REPO_PATH%%/*}"
      REPO_NAME="${REPO_PATH#*/}"
      
      # Chamar script de setup de project
      SETUP_SCRIPT="$LOCAL_PATH/scripts/setup-github-project.sh"
      if [[ -f "$SETUP_SCRIPT" ]]; then
        bash "$SETUP_SCRIPT" --repo-owner "$REPO_OWNER" --repo-name "$REPO_NAME" || \
          echo "  ⚠ Não consegui criar o GitHub Project automaticamente. Execute manualmente:"
          echo "    bash $SETUP_SCRIPT --repo-owner $REPO_OWNER --repo-name $REPO_NAME"
      else
        echo "  ⚠ Script setup-github-project.sh não encontrado"
      fi

      # Criar/atualizar taxonomia de labels (priority:*, complexity:*, type:*, agent:*, status:*)
      echo ""
      echo "→ Configurando taxonomia de labels (priorização e desenvolvimento autônomo)..."
      LABELS_SCRIPT="$LOCAL_PATH/scripts/setup-github-labels.sh"
      if [[ -f "$LABELS_SCRIPT" ]]; then
        bash "$LABELS_SCRIPT" --repo-owner "$REPO_OWNER" --repo-name "$REPO_NAME" || \
          echo "  ⚠ Não consegui criar os labels automaticamente. Execute manualmente:"
          echo "    bash $LABELS_SCRIPT --repo-owner $REPO_OWNER --repo-name $REPO_NAME"
        echo "  ℹ Para habilitar o auto-assign do Copilot coding agent via label"
        echo "    'agent:autonomous-ok', copie .github/workflows/agent-auto-assign.yml"
        echo "    para o repositório e configure o secret COPILOT_AGENT_ASSIGN_TOKEN."
        echo "    Ver docs/label-taxonomy-and-autonomous-dev.md."
      else
        echo "  ⚠ Script setup-github-labels.sh não encontrado"
      fi
    else
      echo "  ⚠ Não consegui extrair owner/repo do git remote: $GIT_REMOTE"
    fi
  else
    echo "  ⚠ Repositório git não configurado (remote.origin.url)"
  fi
else
  echo "  ⚠ GH CLI não encontrado — pulando criação automática de GitHub Project e labels"
  echo "    Para criar manualmente, execute: ./scripts/setup-github-project.sh"
  echo "    e: ./scripts/setup-github-labels.sh"
fi
