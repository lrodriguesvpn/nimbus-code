---
name: "speckit-interview"
description: "Conduct a discovery interview (business/infra/security/LGPD) for a new feature, live or from a transcript, and save it as specs/<feature-slug>/interview.md ready for /speckit-specify."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "nimbus-code"
  source: "presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). This is a
**manual precursor step** to `/speckit-specify` — it exists so a human (BA/ADE)
can run the standard discovery interview today, before the Teams-based
automation from `specs/018-nimbus-agent-intake/spec.md` (User Story 5) exists.

## Pre-Execution Checks

**Check for extension hooks (before interview)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_interview` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing command invocations from hook command names, replace dots (`.`) with hyphens (`-`).
- For each executable hook, output the appropriate block (optional/mandatory) following the same convention as `/speckit-specify`'s Pre-Execution Checks, and actually invoke mandatory hooks before proceeding.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently.

## Outline

1. **Parse the input into two parts**:
   - **Feature description** (mandatory): a short business description of the demand — this is what names the feature, exactly like `/speckit-specify` requires today. If the user's entire input is a large pasted transcript with no separate short description, **ask for a one-line description first** before continuing — do not attempt to derive a feature name from a full transcript dump.
   - **Transcript** (optional): detect either (a) a pasted block of conversation/notes distinguishable from the short description (e.g., introduced by a line like "transcript:", "segue a conversa:", multiple speaker turns, or clearly much longer prose than a one-line description), or (b) a file path reference the user gives you (e.g., "usar o transcript em ~/OneDrive/.../reuniao-cliente-x.txt" or a relative path in the repo). If a file path is given, read it with the `view` tool. If neither is present, there is no transcript — the entire interview will be conducted live, question by question.

2. **Generate a concise short name** (2-4 words) for the feature, using the exact same rules `/speckit-specify` step 1 uses (action-noun format, preserve acronyms, kebab-case-ready). Use only the feature description for this — never the transcript content.

3. **Create the feature directory deterministically** — do not re-derive the slug/numbering algorithm in prose. Run:
   ```bash
   .specify/scripts/bash/create-new-feature.sh --json --short-name "<generated short name>" "<feature description, transcript stripped out>"
   ```
   - This creates `specs/<prefix>-<short-name>/`, scaffolds an **empty** `spec.md` from the resolved `spec-template` (untouched — filling it is `/speckit-specify`'s job, not this skill's), and persists `.specify/feature.json` with `feature_directory` — exactly the same mechanism `/speckit-specify` relies on downstream.
   - Any inline `EPIC_ISSUE=<N>` token in the feature description is auto-detected and persisted by the script itself — you do not need to extract it yourself.
   - Parse the script's JSON output (`SPEC_FILE`) to derive the feature directory (its dirname). Call this `INTERVIEW_FEATURE_DIRECTORY`.
   - If the script reports the directory already exists (rare — e.g., re-running after a partial failure), pass `--allow-existing-branch` and retry.

4. **Resolve and copy the interview template**:
   - Resolve `interview-template` the same way other feature-artifact templates are resolved: prefer `.specify/presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md`; if this repository itself IS the standards template repo (no `.specify/presets/` copy, or it does not exist), fall back to `presets/nimbus-code-standards/templates/feature-artifacts/interview-template.md`.
   - Copy it to `INTERVIEW_FEATURE_DIRECTORY/interview.md`.

5. **Determine the interview mode**: if the feature description or transcript strongly suggests a trivial/isolated change (S0/S1 territory — a doc fix, an isolated function, no external dependency), propose **Fast-Track** and ask the operator to confirm; otherwise default to **Completo**. Never silently assume Fast-Track without a one-line confirmation — it's cheap to ask, expensive to redo an under-scoped interview.

6. **If a transcript was provided**: evaluate it against every question in Blocos 1–4 of `interview.md` (respecting the Fast-Track ⚡ subset if that mode was chosen), classifying each as:
   - **Coberto** — a clear, actionable answer is present in the transcript.
   - **Ambíguo** — the topic was touched but the answer isn't actionable (vague, hedged, contradictory).
   - **Ausente** — not addressed at all.

   Never infer or invent an answer for Segurança, Infraestrutura, or LGPD questions from indirect context — if it's not explicitly stated, it's `Ausente` or `Ambíguo`, not a guess.

7. **Ask the operator only what's missing**:
   - For every question marked `Ambíguo` or `Ausente` (within the chosen mode's scope — Fast-Track only asks its ⚡ subset), ask it conversationally — group by block if that reads more naturally, but never re-ask something already `Coberto`.
   - If there was no transcript at all, this is simply the full live interview: ask every question in the chosen mode's scope, in order, conversationally (not as a rigid item-by-item form — see "Como usar este modelo" in the template for tone).
   - Apply the golden rule from the template: if the operator starts describing **how** the system should be built (tech, framework, architecture), note it aside and redirect — this interview is about **what** and **why**, never **how**.
   - Apply the LGPD shortcut from the template: if Bloco 4, question 1 is a clear "no personal data", mark questions 2–5 as `N/A — sem dado pessoal identificado` and don't force them.
   - If, after asking, an item still has no answer (operator doesn't know), record it explicitly as `[NEEDS CLARIFICATION: <what's missing>]` in the Encerramento's "Pendências" list — never leave it silently blank.

8. **Fill `interview.md` completely**:
   - Cabeçalho: Data (today), Solicitante/Cliente, Facilitador (your agent identity, e.g. "Nimbus Agent (sessão manual)", or a human name if the operator says they're filling it on someone else's behalf), Canal, Feature slug (= `INTERVIEW_FEATURE_DIRECTORY`'s directory name), Prioridade inferida (from Bloco 1 question 7's answer — never spoken aloud as P0–P3 to the operator), Versão deste modelo (copy from the template's own header comment), Modo desta entrevista, Duração real (your best estimate of elapsed conversation, or "não medida" if conducted from a transcript with no timing info).
   - All 4 blocos: replace every bracketed prompt with the actual answer gathered (live or from transcript).
   - Encerramento: 3–5 line summary read back to the operator for confirmation, the Pendências list, who validates the resulting `spec.md`, and duração real.
   - Checklist de Cobertura Mínima: fill the 3-state table (Coberto/Ambíguo/Ausente) for every row based on what was actually gathered.
   - Saída Estruturada (YAML): fill the `interview_output` block with real values derived 

## Mandatory Post-Execution Validation (Interview Completeness)

After filling `interview.md`, run the deterministic validator **always**:

```bash
.specify/scripts/bash/validate-interview-completeness.sh --file "$INTERVIEW_FEATURE_DIRECTORY/interview.md"
```

- If the validator reports unresolved placeholders, reopen `interview.md` and finish the missing fields.
- If the validator reports the YAML block is absent, that is a warning only; the markdown interview may still be accepted, but the YAML block is recommended whenever possible.

## Mandatory Post-Execution Hooks

- If `.specify/extensions.yml` defines hooks under `hooks.after_interview`, run them after the completeness validator passes.
- Respect the same optional/mandatory hook behavior as the pre-execution stage.

## Completion Report

When done, tell the operator:
- the resolved feature slug / directory;
- whether the interview was Fast-Track or Completo;
- what major areas were covered;
- what is still pending (if anything) before `/speckit-specify`.

## Quick Guidelines

- Keep the interview about **what** and **why**, not **how**.
- Never invent answers for Security, Infrastructure, or LGPD.
- Prefer explicit `N/A` / `[NEEDS CLARIFICATION]` over silent omission.
- When the transcript already answers a question, do not ask it again.

## Done When

- `specs/<feature-slug>/interview.md` exists and is complete.
- The deterministic validator passes.
- Any required after-hooks ran successfully.
- The operator has a concise completion report with next steps.
