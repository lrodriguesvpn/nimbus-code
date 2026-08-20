---
name: "speckit-taskstoissues"
description: "Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/taskstoissues.md"
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before tasks-to-issues conversion)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_taskstoissues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing command invocations from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
1. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.
1. From the executed script, extract the path to **tasks**.
1. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

1. **Derive `--repo-owner`/`--repo-name`** from the remote URL parsed above (the `owner/repo` segment of the GitHub/GHE URL). All hierarchy-related script invocations below use these two values plus `GH_HOST` inherited from the environment (defaults to `venha-pra-nuvem.ghe.com` — do not override it unless the remote points elsewhere).

1. **Bootstrap the Epic → Feature → User Story hierarchy** (specs/005-epic-feature-us-ghe-hierarchy). This uses `.specify/scripts/bash/create-github-issue-hierarchy.sh`, a bash+`gh` CLI helper (same idiom as `scripts/setup-github-project.sh`) that handles GraphQL sub-issue linking (`addSubIssue`), native Issue Type assignment (`updateIssueIssueType`) with graceful label fallback (`type:epic`/`type:feature`/`type:user-story`/`type:task`), marker-based deduplication (an HTML comment `<!-- speckit-feature-id: ... -->` / `<!-- speckit-us-id: ... -->` in the issue body — same pattern as the `speckit-deduplication-by-id` entry in `docs/reuse-catalog.yaml`), and the 90/100 sub-issue limit alert. Run it for real (not a dry-run) unless the user explicitly asked for a preview:
   1. Read `epic_issue` from `.specify/feature.json` (via `FEATURE_DIR/../feature.json` or the repo-root `.specify/feature.json` — whichever the project resolves as the active feature's metadata). If the key is absent or null, treat the feature as having no Epic parent — this is not an error.
   2. Ensure the Feature issue exists and is linked to the Epic (if any):
      ```bash
      .specify/scripts/bash/create-github-issue-hierarchy.sh ensure-feature \
        --repo-owner <owner> --repo-name <repo> \
        --feature-dir "<FEATURE_DIR>" \
        [--epic-issue <N> if epic_issue was set] \
        --json
      ```
      Parse `feature_issue` from the JSON result printed on the last line — this is `FEATURE_ISSUE`. The command is idempotent: re-running it reuses the existing Feature issue (matched by its hidden marker) instead of creating a duplicate, and only adds the Epic link if it is missing.
   3. Parse every User Story section header from `tasks.md` (pattern: a `## Phase N: User Story M ...` or `## Phase N: User Story M — ...` heading — the em dash/hyphen and trailing `(Priority: ...)` suffix vary, only `User Story M` and the title text between the dash/em dash and the trailing parenthetical matter). For each one found, in order:
      ```bash
      .specify/scripts/bash/create-github-issue-hierarchy.sh ensure-user-story \
        --repo-owner <owner> --repo-name <repo> \
        --feature-dir "<FEATURE_DIR>" \
        --us-id US<M> --title "<extracted US title>" \
        --parent-issue <FEATURE_ISSUE> \
        --json
      ```
      Parse `user_story_issue` from the result and keep an in-memory map `US<M> -> issue number` for the task-linking step below. This is also idempotent (reused by marker on re-run) and skips re-linking if already a sub-issue of the Feature.
   4. If the script prints a line starting with `✗ Parent #... já tem N sub-issues` (hard limit reached, exit code 2) for either the Epic or the Feature, **stop and report this clearly to the user** — the corresponding link was NOT created (the issue itself may still exist), and the Epic/Feature must be split into smaller pieces before continuing. Do not silently ignore this.
   5. If the script reports `[MODO DEGRADADO]` (org without native Issue Types), continue normally — it already applied the `type:*` label fallback; just surface the message once to the user instead of repeating it per issue.

1. **Fetch existing issues for deduplication**: Before creating anything, build the set of task IDs you are about to process from `tasks.md` (each is a `T` followed by three digits, e.g. `T001`). Then use the GitHub MCP server's `list_issues` tool to look for issues that already cover those IDs. Do not pass a `state` value, since omitting it makes the tool return both open and closed issues. Request `perPage: 100` to keep the number of calls down, and since the tool uses cursor-based pagination, request pages with the `after` parameter (using the `endCursor` from the previous response). For each issue title, match it against the task ID pattern `\bT\d{3}\b` (word boundaries so tokens like `ST001` or `T0010` are not matched by mistake; this also recognises titles written as `T001 ...`, `T001: ...` or `[T001] ...`) and, when it matches one of your task IDs, mark that ID as already having an issue. Stop paginating as soon as every task ID has been matched, or when there are no more pages, so you do not keep fetching the whole repository's issue history once all task IDs are accounted for. This bounds the number of calls on repos with large issue histories and still prevents duplicates when the command is re-run after `tasks.md` is regenerated or the skill is re-invoked. Report matches as `✓ T001 já existe (#N) — verificando vínculo` so the operator can see that dedup is happening at the sub-issue linking step below, not just at issue-creation time.

1. For each task in the list, use the GitHub MCP server to create a new issue in the repository that is representative of the Git remote. Task lines in `tasks.md` start with a markdown checkbox, so first strip the leading `- [ ]` (and any `[P]` / `[US#]` markers) to recover the task ID and its description. Create the issue with a single canonical title of the form `T001: <description>`, with the ID written once followed by the task description (for example, the line `- [ ] T001 Create project structure` becomes the title `T001: Create project structure`).
   - **Skip** any task whose ID is already present in the set of existing issues from the previous step, and report it (for example, `T001 already has an issue, skipping`). Do not skip the linking sub-step below just because issue creation was skipped — an existing Task issue may still be missing its sub-issue link (e.g. if `tasks.md` was regenerated with new `[USN]` tags, or if the hierarchy automation is being adopted on a repo that already had flat Task issues).
   - Only create issues for tasks that do not yet have a matching issue.
   - **Link the Task issue into the hierarchy** (specs/005-epic-feature-us-ghe-hierarchy), whether the issue was just created or already existed: find the task's `[USN]` tag from `tasks.md` and look up the matching `US<N> -> issue number` from the bootstrap step above. Then run:
     ```bash
     .specify/scripts/bash/create-github-issue-hierarchy.sh link-task \
       --repo-owner <owner> --repo-name <repo> \
       --parent-issue <the US issue number for this task's [USN] tag, or FEATURE_ISSUE if the task has no [USN] tag> \
       --child-issue <this task's issue number> \
       --json
     ```
     This both links the Task as a sub-issue (skipping if already linked, warning instead of silently reparenting if the Task is already a sub-issue of something else, and enforcing the 90/100 sub-issue limit on the parent) and applies the native `Task` Issue Type (or the `type:task` label fallback — on top of, not instead of, the priority/complexity/agent labels computed in the next step).

2. **Compute labels before creating each issue**. Every Task issue MUST receive the full mandatory label set below, derived from the task text plus the surrounding section/spec context:
   - **Type**: always apply `type:task`
   - **Priority**: infer from the closest explicit marker in the current section/task (`Priority: P0/P1/P2/P3`, `P0-blocker`, etc.); if no explicit priority exists, default to `priority:P2-medium`
   - **Complexity**: classify the task itself (not just the parent feature) using the S0–S4 scale from the constitution:
    - `complexity:S0` → documentation/text/checklist-only work
    - `complexity:S1` → isolated script/config/single-file change
    - `complexity:S2` → one module/workflow/component with localized validation
    - `complexity:S3` → cross-module/cross-repo integration or workflow orchestration
    - `complexity:S4` → architecture/security-sensitive/org-admin/data-sensitive work, including GitHub App creation/installation, org-wide permission changes, or security governance tasks
    - If still ambiguous after reading the task + plan/spec, inherit the feature complexity declared in `tasks.md`/`plan.md`
   - **Agent routing**:
    - apply `agent:needs-human` when the task is tagged `[Humano]`, explicitly says manual/human, belongs to a bounded context with `autonomous_ok: false`, or requires privileged/org-admin/security/GitHub App actions
    - otherwise apply `agent:autonomous-ok`
   - **DORA**: add `dora:*` labels only when the task explicitly impacts one of the four DORA domains
3. **Validate required labels exist in the target repository before issue creation**. If any mandatory label above does not exist (for example `type:task`), stop and report the missing taxonomy clearly, instructing the operator to run `scripts/setup-github-labels.sh` in that repository before retrying. Do not silently create partially labeled Task issues.
4. Create the issue body using the Nimbus-Code hybrid task contract so the issue is directly executable by a human or agent without rereading the spec/plan:

   ```markdown
   ## Contexto
   [o mínimo necessário para entender o problema]

   ## Objetivo
   [ação clara e acionável]

   ## Resultado Esperado
   [entregável verificável]

   ## Critérios de Aceite
   - [ ] [critério 1 verificável]

   ## Passos Operacionais
   1. [passo 1]
   2. [passo 2]

   ## Dependências
   [Nenhuma | IDs de tasks/issues bloqueadoras]

   ## Responsável
   Agente: [sim/não]
   Humano: [sim/não]

   ## Labels Aplicadas
   - priority:...
   - complexity:...
   - type:task
   - agent:...
   - dora:... (se aplicável)

   ## Estimativa de Esforço
   - Tokens (agente): ~X–Y mil
   - Horas (humano): ~X–Y horas

   ## Referência
   - AC-ID: AC-N
   - Feature: specs/<feature-slug>
   ```

   If the task does not have an explicit AC or feature link, keep those fields as `N/A` instead of omitting them.
5. When a Task is human-only and concerns GitHub App, security administration, org-level permissions, or other privileged setup, make the issue body explicit that it requires human execution and include any operator-routing instruction already provided by the caller/project context instead of letting the agent self-assign it.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL

## Post-Execution Checks

**Check for extension hooks (after tasks-to-issues conversion)**:
Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_taskstoissues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing command invocations from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently
