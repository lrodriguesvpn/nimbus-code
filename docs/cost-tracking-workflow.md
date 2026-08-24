# Cost Tracking in Nimbus Code

**Integrated Extension**: [spec-kit-cost](https://github.com/Quratulain-bilal/spec-kit-cost)  
**Version**: ≥1.0.0  
**Installed via**: `specify extension install cost`

---

## Overview

Every Spec Kit SDD feature has a real dollar cost:

- **Input tokens** × pricing per million tokens (varies by integration)
- **Output tokens** × pricing per million tokens (2–5× more expensive than input)
- **Multiple phases**: specify → plan → tasks → implement

The cost tracker helps answer:
- **"How much did this feature cost to build?"** → `/speckit.cost.report`
- **"Which LLM would have been cheapest?"** → `/speckit.cost.compare`
- **"Are we over budget?"** → `/speckit.cost.budget show`
- **"Export for finance/dashboard"** → `/speckit.cost.export`

---

## Quick Start

### 1. After each phase, record the cost

After running `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, or `/speckit.implement`, run:

```bash
/speckit.cost.track phase=specify input_tokens=12345 output_tokens=3210
```

**Where to find token counts**:
- **Copilot Agent**: End-of-session summary shows "Tokens: IN=X, OUT=Y"
- **LLM Chat**: Check the provider's token counter (Claude/ChatGPT interfaces show it)
- **Logs**: Check your agent transcript or CLI output

### 2. Review cost breakdown

```bash
/speckit.cost.report
```

Output example:
```
Feature: feature/logout-button
Scope:   feature

GROUP        RUNS  INPUT TOK   OUTPUT TOK   COST (USD)
-------------------------------------------------------
specify      1     12,345      3,210        $0.0858
plan         1     28,400      9,150        $1.2375
tasks        1     15,000      4,800        $0.4350
implement    4     180,000     52,000       $11.6400
-------------------------------------------------------
TOTAL        7     235,745     69,160       $13.3983

Budget: $20.00 cap   $13.3983 spent   $6.6017 remaining (67% used)
```

### 3. Set per-feature budgets (optional)

```bash
/speckit.cost.budget set scope=feature amount=20
/speckit.cost.budget set scope=phase phase=implement amount=15
/speckit.cost.budget mode=warn  # or 'block' to fail when over cap
```

### 4. Compare integrations

After a few features, see which LLM would have been cheapest:

```bash
/speckit.cost.compare
```

Output example:
```
MODEL                   PROJECTED COST    Δ vs ACTUAL    NOTE
---------------------------------------------------------------------
gemini-2-5-pro          $4.12             -$9.28 (-69%)
claude-haiku-4-5        $5.30             -$8.10 (-60%)
gpt-4o                  $7.04             -$6.36 (-47%)
claude-sonnet-4-6       $13.40            $0.00 (0%)     ← actual
claude-opus-4-7         $67.00            +$53.60 (+400%)
```

### 5. Export for finance/BI

```bash
/speckit.cost.export format=csv source=summary out=./monthly-cost.csv
```

Produces a small, finance-ready CSV with one row per `(feature, phase, model)` group.

---

## Configuration

Cost tracker configuration lives in `.specify/cost/cost-config.yml`. It includes:

- **Pricing rates** by integration (Claude, Copilot, Gemini, OpenCode)
- **Budget caps** per feature and per phase
- **Storage paths** (ledger and summary files)

### Updating pricing

If your organization negotiates different rates with Claude/OpenAI/Google, edit `.specify/cost/cost-config.yml`:

```yaml
pricing:
  rates:
    claude-sonnet-4-6:
      input_per_mtok: 3.00  # $3 per million input tokens
      output_per_mtok: 15.00  # $15 per million output tokens
```

Rate changes apply to all future `/speckit.cost.track` calls.

---

## Data Storage

Cost data is **append-only and diff-friendly**:

```
.specify/cost/
├── ledger.jsonl          # One record per /speckit.cost.track run
└── summary.json          # Rolled-up totals by feature/phase/integration
```

Both are JSON (not binary), so they:
- Diff cleanly in PR reviews
- Are scriptable for custom analysis
- Store no secrets or prompts (only token counts and metadata)

---

## What It Does NOT Do

- ❌ Capture prompts or responses (privacy-safe — only token counts)
- ❌ Auto-instrument agents (you pass token counts in, or parse transcripts)
- ❌ Enforce budgets at the agent level (`block` mode only prevents `/speckit.cost.track` from succeeding, but the agent run already happened)
- ❌ Include token cache discounts (model-dependent; counts assume cache miss)

---

## Workflow Integration

### With `/speckit.specify` + `/speckit.plan` + `/speckit.tasks` + `/speckit.implement`

Standard Nimbus-Code workflow:

```
/speckit.specify "Add logout button"        → get token count
/speckit.cost.track phase=specify ...       → record cost

/speckit.plan                               → get token count
/speckit.cost.track phase=plan ...          → record cost

/speckit.tasks                              → get token count
/speckit.cost.track phase=tasks ...         → record cost

/speckit.implement                          → get token count
/speckit.cost.track phase=implement ...     → record cost

/speckit.cost.report                        → see total cost
```

---

## Compliance & Audit

- **Versioned**: `.specify/cost/cost-config.yml` is checked into git, so budget changes are auditable
- **No telemetry**: All cost tracking is local-only (no network calls)
- **No secrets**: Ledger stores no API keys, prompts, or sensitive data
- **Multi-project**: Run `/speckit.cost.report scope=all` to see portfolio cost

---

## Commands Reference

| Command | Purpose |
|---|---|
| `/speckit.cost.track` | Record token usage and cost for the current phase |
| `/speckit.cost.report` | Show cost breakdown for feature or project |
| `/speckit.cost.budget` | Set, view, or check per-phase/per-feature budget caps |
| `/speckit.cost.compare` | Re-price the same workload across integrations |
| `/speckit.cost.export` | Export ledger or summary as CSV/JSON |

---

## See Also

- [spec-kit-cost repository](https://github.com/Quratulain-bilal/spec-kit-cost)
- `docs/ai-code-quality-and-observability.md` — section 8 (hybrid model cost)
- `.specify/cost/cost-config.yml` — local configuration
