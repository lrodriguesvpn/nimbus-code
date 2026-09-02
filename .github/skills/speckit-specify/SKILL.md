---
name: "speckit-specify"
description: "Create or update the feature specification from a natural language feature description."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/specify.md"
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before specification)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_specify` key
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

The text the user typed after `/speckit-specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

1. **Generate a concise short name** (2-4 words) for the feature:
   - Analyze the feature description and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Examples:
     - "I want to add user authentication" → "user-auth"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"

2. **Branch creation** (optional, via hook):

   If a `before_specify` hook ran successfully in the Pre-Execution Checks above, it will have created/switched to a git branch and output JSON containing `BRANCH_NAME` and `FEATURE_NUM`. Note these values for reference, but the branch name does **not** dictate the spec directory name.

   If the user explicitly provided `GIT_BRANCH_NAME`, pass it through to the hook so the branch script uses the exact value as the branch name (bypassing all prefix/suffix generation).

3. **Create the spec feature directory**:

   **Reuse a pending interview, if present (Nimbus-Code preset)**: before generating anything new, check `.specify/feature.json` for an existing `feature_directory`. If that path exists on disk **and** contains an `interview.md` (created by `/speckit-interview`), this feature was already started there — do not generate a new short name/number and do not run the directory-creation logic below. Instead:
   - Set `SPECIFY_FEATURE_DIRECTORY` to that exact existing path.
   - Set `SPEC_FILE` to `SPECIFY_FEATURE_DIRECTORY/spec.md` (already scaffolded, empty, by `/speckit-interview`'s call to `create-new-feature.sh` — do not recreate it).
   - Read `interview.md` and treat it as the **primary source** for the spec content in the steps below (objective, acceptance criteria, bounded context signal, etc.) — any additional `$ARGUMENTS` given to this `/speckit-specify` invocation only fill gaps `interview.md` still marks `Ambíguo`/`Ausente`/`[NEEDS CLARIFICATION]`, they do not override what the interview already captured.
   - Skip the rest of this step (directory resolution/creation) entirely and continue at step 4.

   If no such pending interview exists (the common case — most features are created directly by `/speckit-specify` without a prior `/speckit-interview`), proceed with the normal resolution below.

   Specs live under the default `specs/` directory unless the user explicitly provides `SPECIFY_FEATURE_DIRECTORY`.

   **Resolution order for `SPECIFY_FEATURE_DIRECTORY`**:
   1. If the user explicitly provided `SPECIFY_FEATURE_DIRECTORY` (e.g., via environment variable, argument, or configuration), use it as-is
   2. Otherwise, auto-generate it under `specs/`:
      - Check `.specify/init-options.json` for `feature_numbering` (preferred) or `branch_numbering` (deprecated, migration only — will be removed in a future release)
      - If `"timestamp"`: prefix is `YYYYMMDD-HHMMSS` (current timestamp)
      - If `"sequential"` or absent: prefix is `NNN` (next available 3-digit number after scanning existing directories in `specs/`)
      - Construct the directory name: `<prefix>-<short-name>` (e.g., `003-user-auth` or `20260319-143022-user-auth`)
      - Set `SPECIFY_FEATURE_DIRECTORY` to `specs/<directory-name>`
      - If `branch_numbering` was used (and `feature_numbering` was absent), emit a one-line warning: "⚠️ `branch_numbering` in init-options.json is deprecated. Rename to `feature_numbering`."

   **Create the directory and spec file**:
   - `mkdir -p SPECIFY_FEATURE_DIRECTORY`
   - Resolve the active `spec-template` through the Spec Kit preset/template resolution stack (equivalent to `specify preset resolve spec-template`)
   - Copy the resolved `spec-template` file to `SPECIFY_FEATURE_DIRECTORY/spec.md` as the starting point
   - Set `SPEC_FILE` to `SPECIFY_FEATURE_DIRECTORY/spec.md`
   - Persist the resolved path to `.specify/feature.json`:
     ```json
     {
       "feature_directory": "<resolved feature dir>"
     }
     ```
     Write the actual resolved directory path value (for example, `specs/003-user-auth`), not the literal string `SPECIFY_FEATURE_DIRECTORY`.
     This allows downstream commands (`/speckit-plan`, `/speckit-tasks`, etc.) to locate the feature directory without relying on git branch name conventions.
   - **Optional Epic link** (specs/005-epic-feature-us-ghe-hierarchy): scan the raw feature description text for an `EPIC_ISSUE=<N>` token (case-insensitive, `N` a positive integer — the number of an existing Epic issue in the GHE repo). If present:
     - Strip the `EPIC_ISSUE=<N>` token out of the feature description before using it as spec content.
     - Merge `"epic_issue": <N>` (as a JSON number, not a string) into `.specify/feature.json` alongside `feature_directory` — do not overwrite other existing keys (`bounded_contexts`, `repos`, etc.) already in that file.
     - Equivalently, `.specify/scripts/bash/create-new-feature.sh` accepts a `--epic-issue <N>` flag that does this same merge when the feature is created via that script directly.
     - If `EPIC_ISSUE` is absent, do not add the key at all — downstream `/speckit-taskstoissues` treats a missing `epic_issue` as "no Epic parent" and creates the Feature issue without a parent link (not an error).
     - **Edge case — Epic does not exist yet**: this command does NOT create the Epic issue automatically (Epics are created manually in the GHE UI or via `gh issue create --label type:epic`, see `docs/developer-guide.md` seção 4.3, Passo 1). If the user did not provide `EPIC_ISSUE`, do not block spec creation — inform them they can add `"epic_issue": <N>` to `.specify/feature.json` manually later, before running `/speckit-taskstoissues`.

   **IMPORTANT**:
   - You must only create one feature per `/speckit-specify` invocation
   - The spec directory name and the git branch name are independent — they may be the same but that is the user's choice
   - The spec directory and file are always created by this command, never by the hook

4. Load the resolved active `spec-template` file to understand required sections.

5. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.

6. Follow this execution flow:
    1. Parse user description from arguments
       If empty: ERROR "No feature description provided"
    2. Extract key concepts from description
       Identify: actors, actions, data, constraints
       Also identify backlog hierarchy context (EPIC, FEATURE e User Stories/US)
    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts feature scope or user experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
    4. Fill User Scenarios & Testing section
       If no clear user flow: ERROR "Cannot determine user scenarios"
    5. Generate Functional Requirements
       Each requirement must be testable
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
    6. Define Success Criteria
       Create measurable, technology-agnostic outcomes
       Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
       Each criterion must be verifiable without implementation details
    7. Identify Key Entities (if data involved)
    8. Define backlog hierarchy mapping for project views:
      - EPIC (tema macro)
      - FEATURE (recorte da entrega)
      - US (fatias independentes de valor)
    9. Return: SUCCESS (spec ready for planning)

   9. **Hybrid governance enforcement (Nimbus-Code preset)**:
     - Ensure the generated spec includes explicit guidance for **hybrid collaboration** (agent + human responsibilities / handoff).
     - Ensure acceptance criteria are in strict **BDD** form (`Given/When/Then`) with unique IDs (`AC-N`).
     - Ensure the spec has an explicit section "Backlog Hierarchy (EPIC/FEATURE/US)" for downstream sync/board views.
     - If the feature context is **WEB**, ensure the spec explicitly states **Impeccable** as the design standard.
     - If rollout/toggle strategy is mentioned in scope, ensure the spec references **OpenFeature** as the abstraction standard.
     - **Bounded Context validation (MultiRepo, AC-2)**: before filling the "Bounded Context" row of the header table, read `docs/bounded-contexts.yaml` from the repo root.
       - If the file does not exist, or has no entries under `contexts`, MultiRepo isn't configured for this project — fill the field with the best-guess bounded context name as before, nothing to validate against.
       - If the file exists, collect the registered `slug` values and compare the bounded context you are about to write against them (case-insensitive; compare on slug form, e.g. "Order Management" ~ `order-management`).
       - If it matches a registered slug, write that registered `slug` (not an ad-hoc free-text label) into the "Bounded Context" field.
       - **If it does not match any registered slug**, do not silently accept an ad-hoc name and do not add the entry yourself. Instead:
         1. Stop before finalizing the spec and clearly flag the divergence to the Dev, listing every slug currently registered in `docs/bounded-contexts.yaml`.
         2. Propose a new entry (`slug`, `description`, `repository`, `stack`, `team`, `autonomous_ok`) for the Dev to review — registering a bounded context affects org-wide routing (`/speckit-taskstoissues`, `scripts/setup-github-project.sh`), so it requires explicit confirmation, not a silent agent decision.
         3. Ask the Dev to either confirm the proposed new entry (to be added to `docs/bounded-contexts.yaml`, typically via its own PR) or pick one of the existing registered slugs instead.
         4. Only write the spec's "Bounded Context" field once the Dev confirms — either with the newly registered slug or an existing one. Do not proceed with an unregistered/ad-hoc value.
       - **Automatic context graph generation** (specs/014-brownfield-multirepo-context-awareness/, AC-2, AC-5): once the "Bounded Context" field is resolved to a registered slug, invoke `scripts/generate-context-graph.sh <slug> --feature <SPECIFY_FEATURE_DIRECTORY basename>` **before** finalizing `spec.md` — this must run automatically, without the Dev needing to remember a separate command (AC-3, "same ergonomics as greenfield").
         - If the script exits `0` and reports repos analyzed: `SPECIFY_FEATURE_DIRECTORY/graph.yaml` and `graph.md` now exist and reflect the bounded context's repos — proceed normally; the spec is being opened with the context graph already available for the eventual `/speckit-plan`.
         - If the script exits `0` but warns that the bounded context has no repos mapped (`docs/bounded-contexts.yaml` exists but the context is empty, or the file itself doesn't exist): surface the warning to the Dev once, then **continue the spec flow without blocking** — the graph can be generated later once the context is mapped (AC-5, edge case: never block spec creation on a missing/empty bounded context).
         - If the script exits non-zero for a real error (e.g., `docs/bounded-contexts.yaml` has invalid YAML): surface the error clearly, but still do not abort the whole `/speckit-specify` flow — the Dev can fix the file and re-run `scripts/generate-context-graph.sh` manually afterward.
         - **Never invoke `scripts/harvest-patterns.sh`** from this flow — that script is exclusively on-demand and human-initiated (FR-011); `/speckit-specify` only triggers `generate-context-graph.sh`.
      - **Discovery interview coverage check (Nimbus-Code preset)**: this check is about *what* the requester needs, never *how* it will be built — do not let it pull implementation detail into the spec.
        - **If `SPECIFY_FEATURE_DIRECTORY/interview.md` already exists** (reused from a prior `/speckit-interview` run per step 3 above), it is already the authoritative record of the 4-block coverage — including its own "Checklist de Cobertura Mínima" 3-state table (Coberto/Ambíguo/Ausente). Use it directly: treat any row still `Ambíguo` or `Ausente` there as the gap list, instead of re-deriving coverage from scratch against the raw feature description.
        - **Otherwise** (the common case — no prior `/speckit-interview` was run): resolve the active `interview-template` (`presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md`, or its `.specify/presets/` mirror) and read its "Checklist de Cobertura Mínima" section — the 4 mandatory blocks are: **Negócio** (objective/why, done-criteria, user profiles, out-of-scope, acceptance criteria — minimum 4 measurable/observable), **Infraestrutura** (hosting/reference pattern, who accesses, affected repos/bounded contexts), **Segurança** (sensitivity, authorization profiles), **LGPD** (personal data presence, legal basis).
        - Compare the raw feature description (arguments) — and, if the Dev attached one, an interview transcript — against these 4 blocks.
        - If a block is **explicitly answered** (even briefly, e.g., "sem dado pessoal envolvido"), treat it as covered — do not demand verbose detail. If a block is **completely absent** from the input, it is a gap.
        - If the input already reads as a filled interview (clearly organized by these 4 blocks, e.g., produced by a discovery meeting), copy it into `SPECIFY_FEATURE_DIRECTORY/interview.md` using the `interview-template` structure, preserving the answers given, before continuing.
        - For every gap found, add it as a `[NEEDS CLARIFICATION: <specific missing block>]` candidate — respecting the existing "Maximum 3 [NEEDS CLARIFICATION] markers total" limit from step 6.3, and prioritizing by impact: **Negócio > Segurança/LGPD > Infraestrutura** > other technical details. Never invent an infra, security, or LGPD answer to fill a gap silently — an unanswered mandatory block must surface as a clarification, not a guess.
        - This check never blocks spec creation by itself — it only feeds candidates into the existing clarification-marker flow (step 8.c below), which already has its own resolution path.

7. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the feature description (arguments) while preserving section order and headings.

8. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `SPECIFY_FEATURE_DIRECTORY/checklists/requirements.md` using the checklist template structure with these validation items:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]

      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]

      ## Content Quality

      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed

      ## Requirement Completeness

      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Acceptance criteria use Given/When/Then with AC-N IDs
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified

      ## Feature Readiness

      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification
      - [ ] Hybrid collaboration guidance is explicit (agent + human)
      - [ ] WEB context explicitly references Impeccable
      - [ ] Rollout/toggle context references OpenFeature abstraction
      - [ ] Bounded Context field matches a slug registered in docs/bounded-contexts.yaml (or the file is absent/empty)
      - [ ] Discovery interview coverage (Negócio, Infraestrutura, Segurança, LGPD) is present or each gap is tracked as [NEEDS CLARIFICATION]

      ## Notes

      - Items marked incomplete require spec updates before `/speckit-clarify` or `/speckit-plan`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed to the Mandatory Post-Execution Hooks section

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user in this format:

           ```markdown
           ## Question [N]: [Topic]

           **Context**: [Quote relevant spec section]

           **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]

           **Suggested Answers**:

           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A      | [First suggested answer] | [What this means for the feature] |
           | B      | [Second suggested answer] | [What this means for the feature] |
           | C      | [Third suggested answer] | [What this means for the feature] |
           | Custom | Provide your own answer | [Explain how to provide custom input] |

           **Your choice**: _[Wait for user response]_
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

## Mandatory Post-Execution Validation (Epic Issue Consistency)

**You MUST run this before reporting completion to the user. Unlike the "Mandatory Post-Execution Hooks" section below, this step is unconditional — it does not depend on `.specify/extensions.yml` existing or any hook being registered. Never skip it.**

This closes a reliability gap (specs/005-epic-feature-us-ghe-hierarchy): the `EPIC_ISSUE=<N>` extraction described in step 3 of the Outline above is prose in the middle of a long multi-step flow — an agent (you, in a future run, or a different session) could skip it without anyone noticing. This step is a deterministic, idempotent, self-healing check implemented in bash, not something you re-interpret from text — it does not rely on you having extracted `EPIC_ISSUE` correctly earlier.

Run:
```bash
.specify/scripts/bash/check-epic-issue-consistency.sh --description "<the original, unmodified feature description text the user typed after /speckit-specify>" --json
```

- Pass the **original raw text** exactly as the user provided it — not a paraphrased or already-stripped version — so the script's own regex extraction is authoritative regardless of what happened in step 3.
- The script is a no-op (exits 0, prints `{"status":"no-op",...}`) when the description has no `EPIC_ISSUE=<N>` token — safe and cheap to always run, even for features with no Epic.
- If it prints `{"status":"fixed",...}`: step 3's extraction was missed or produced a different value, and this script just corrected `.specify/feature.json` for you. Mention this self-correction in the Completion Report so the user is aware.
- If it prints `{"status":"ok",...}`: everything was already consistent — nothing to mention.
- If the script exits non-zero (for example, `.specify/feature.json` does not exist yet — which would indicate step 3 did not run correctly), **do not silently ignore it or declare completion** — report the failure to the user.

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_specify`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_specify` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue to the Completion Report.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing command invocations from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Mandatory hook** (`optional: false`) — **You MUST emit `EXECUTE_COMMAND:` for each mandatory hook**:
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

## Completion Report

Report completion to the user with:
- `SPECIFY_FEATURE_DIRECTORY` — the feature directory path
- `SPEC_FILE` — the spec file path
- Checklist results summary
- Readiness for the next phase (`/speckit-clarify` or `/speckit-plan`)
- If the "Mandatory Post-Execution Validation" step above reported `{"status":"fixed",...}`, mention that `epic_issue` was auto-corrected in `.specify/feature.json` (and to what value)

**NOTE:** Branch creation is handled by the `before_specify` hook (git extension). Spec directory and file creation are always handled by this core command.

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: Use project-appropriate patterns (REST/GraphQL for web services, function calls for libraries, CLI args for tools, etc.)

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)

## Done When

- [ ] Specification written to `SPEC_FILE` and validated against quality checklist
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with feature directory, spec file path, and checklist results
