# Impact Map & Risk Analysis: Hybrid Agent-Human Templates

**Feature Complexity**: S3 (múltiplos módulos + integração entre skills)  
**Risk Level**: Medium  
**Rollback Feasibility**: High

---

## 1. Dependency Impact Analysis

### Direct Dependencies

| Module | Role | Impact if Missing | Mitigation |
|---|---|---|---|
| `spec-template.md` | Defines spec output format | Specs without hybrid header; ambiguity in agent/human roles | Template must be in `.specify/presets/nimbus-code-standards/` before feature rollout |
| `plan-template.md` | Defines plan output format | Plan lacks release strategy, gates, cost tracking sections | Template locked in Git; tested on 2 pilot projects before merge |
| `task-template.md` | Defines GHE issue format | Tasks lack operational steps; humans can't execute without context | Template validated by tech lead before GHE issues published |
| `speckit-specify` skill | Generates spec.md | Feature 005 cannot be specified | Skill atualizado para reforçar BDD, colaboração híbrida e padrão Impeccable em contexto WEB |
| `speckit-plan` skill | Generates plan.md | Feature 005 cannot be planned | Skill atualizado para exigir graph/impact-map, OpenFeature e bloco de custo (SPEC KIT COST) |
| `speckit-tasks` skill | Generates tasks.md | Feature 005 cannot be tasked; no GHE issues published | Skill atualizado para emitir tasks com contrato executável por humano |
| `validate-hybrid-contracts.sh` | Contract validation for fixture outputs | CI pode aceitar mudança regressiva de template | Script executado no workflow de validação para bloquear regressões |
| `constitution.md` | Governance principles | Plan validation fails; no clear responsibility assignment | Existing doc; no changes needed (used as-is in plan validation) |
| `reuse-catalog.yaml` | Pattern library | Duplicate work; no guidance for future features | Updated post-implementation with new pattern entry (tag: `hybrid-dev-templates`) |

### Indirect Dependencies (External)

| System | Role | Impact if Unavailable | Mitigation |
|---|---|---|---|
| GitHub Enterprise (GHE) | Issue tracking & PR workflow | `/speckit-tasks` cannot publish; execution blocked | GHE is operational by design; outage outside scope; fallback: publish tasks.md locally |
| SPEC KIT COST (public GitHub) | Cost tracking reference | Cost transparency fails; tasks lack reference | URL embedded in templates; broken link → automatic issue flagged in CI/CD |
| Nimbus-Code docs | Guidance & ADL | Developers unsure of pattern; adoption friction | Docs updated post-feature with quickstart links |

---

## 2. Risk Assessment Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|---|---|---|---|---|
| **Adoption friction**: Devs confused by new template format | Medium | High | **High** | (1) Pilot validation (2 projects); (2) Internal docs + training; (3) Feature flag (gradual rollout) |
| **Skill generation bugs**: `/speckit-plan` or `/speckit-tasks` produces invalid output | Low | High | **Medium** | (1) Unit + integration tests (>80% coverage); (2) Pilot projects validate output; (3) Tech lead review gates |
| **Cost reference breakage**: SPEC KIT COST GitHub URL becomes stale | Low | Medium | **Low** | (1) Linter checks HTTP 200 on URL; (2) Fallback: URL → Issue template automatically |
| **Performance regression**: Template resolution takes 3x longer | Low | Medium | **Low** | (1) Benchmark before/after; (2) Cache layer if needed; (3) Async processing for large projects |
| **Backward compatibility**: Existing projects break with new templates | Medium | High | **High** | (1) Feature flag (dev always on, hml pilot, prod pilot, prod 100%); (2) Old templates remain available; (3) Explicit opt-in for hybrid mode |
| **Data leak**: Cost/effort data in SPEC KIT COST becomes sensitive | Low | High | **Medium** | (1) SPEC KIT COST repo remains public but ephemeral; (2) No PII in estimates; (3) Data retention policy: 90 days |

---

## 3. Rollback Plan

### Scenario: Feature 005 Deployment Fails

**Trigger Conditions**:
- Pilot project 1 or 2 reports "task template unclear" or "unable to execute" (Step 6 of quickstart fails)
- CI/CD lint failures on generated tasks.md (>3 consecutive failures)
- Performance regression >50% in `/speckit-plan` execution time

**Rollback Steps** (estimated 30 min):

1. **Disable Feature Flag** (immediate)
   ```bash
   # In .specify/init-options.json or GitHub Actions environment
   HYBRID_DEV_TEMPLATES_V1=false
   ```
   → All new projects default to old templates

2. **Revert Template Changes** (Git)
   ```bash
   git revert <commit-hash-of-template-changes>
   # Reverts:
   # - spec-template.md (Nimbus-Code header removed)
   # - plan-template.md (gates, ADL, release strategy removed)
   # - task-template.md (operational steps, cost reference removed)
   ```

3. **Revert Skill Updates** (Git)
   ```bash
   git revert <commit-hash-of-skill-changes>
   # Reverts:
   # - /speckit-plan (Phase 0/1 removed; back to original)
   # - /speckit-tasks (operational guidance removed; back to basic)
   ```

4. **Publish Incident** (GitHub Issue)
   ```markdown
   Title: Feature 005 Rollback — Hybrid Templates Disabled
   Label: incident, feature:005
   Severity: P2
   
   Root cause: [brief reason]
   Affected: [pilot projects]
   Status: Rolled back to main branch
   Next: Post-mortem in 24h
   ```

5. **Validate Rollback** (Smoke test)
   ```bash
   # On a fresh project
   /speckit-specify "Test rollback"
   # Verify: spec.md does NOT have "Hybrid Collaboration Model" header
   ```

6. **Communicate** (Slack/Email)
   ```
   "Feature 005 (Hybrid Templates) has been rolled back.
   New features will use standard templates until issue is resolved.
   See Issue #XXX for details."
   ```

**Estimated Time to Rollback**: ~15 min  
**Estimated Time to Restore Service**: ~5 min (after rollback)

---

## 4. Release Strategy & Staged Rollout

### Rollout Plan

| Stage | Audience | Duration | Flag Setting | Validation Criteria |
|---|---|---|---|---|
| **Dev** | Developers (internal) | Always on | `HYBRID_DEV_TEMPLATES_V1=true` | Feature tests pass; local development works |
| **Pilot (HML)** | 2 pilot projects | 1 week | `HYBRID_DEV_TEMPLATES_V1=true` (opt-in) | Quickstart Steps 1–9 all pass; pilot devs report "clear" on task execution |
| **Pilot (Prod)** | 1 production project | 1 week | `HYBRID_DEV_TEMPLATES_V1=true` (opt-in) | No issues reported; cost tracking works; PR review time acceptable |
| **GA (100%)** | All projects | Permanent | `HYBRID_DEV_TEMPLATES_V1=true` | Rollback plan validated; adoption metrics green |

### Kill Switch

**If any stage fails**, activate kill switch:
```bash
# Kill switch (immediate effect, no deployment needed)
HYBRID_DEV_TEMPLATES_V1=false
```

All projects automatically revert to standard templates. No manual intervention required.

---

## 5. Data Integrity & State Management

### What Changes

| Artifact | Behavior Before | Behavior After | State Risk |
|---|---|---|---|
| `spec.md` | No "Hybrid Collaboration Model" | Prepended section with role definitions | **Low** — additive; old content unchanged |
| `plan.md` | No release strategy detail; gates unclear | Release strategy + feature flag + rollback criteria | **Medium** — new sections may confuse users unfamiliar with syntax |
| `tasks.md` | Basic objectives; no operational steps | Detailed steps + cost references; assigned_to field | **High** — breaking change if executor expects "just description"; mitigated by contract validation |
| `GHE Issues` | Simple markdown format | Structured format with headers, tables, role clarity | **High** — template change affects all GHE integrations; mitigated by feature flag |

### Backward Compatibility

- **Old specs remain readable** (no schema breaking change)
- **Old plans remain readable** (new sections additive)
- **Old tasks remain readable** (new GHE template structure might render differently but content preserved)

**Risk**: Tools that parse `tasks.md` or GHE issue bodies by section index may break.  
**Mitigation**: Update parsers to skip unknown sections (robust parsing).

---

## 6. Critical Path & Success Milestones

```
Day 0 (Today):    Feature 005 spec & plan approved
                  ↓
Day 1–2:          Implement Phase 1 (templates + skills)
                  ↓
Day 3–4:          Test on pilot project 1 (Step 1–9 of quickstart)
                  ↓
Day 5–6:          Test on pilot project 2 + production project
                  ↓
Day 7:            Go-live decision
                  - If PASS: enable feature flag prod 100%
                  - If FAIL: activate kill switch, post-mortem
                  ↓
Day 8+:           Monitoring, adoption tracking, cost data collection
```

**Critical Gates**:
- [ ] Day 4 EOD: Pilot 1 quickstart Steps 1–9 pass
- [ ] Day 6 EOD: Pilot 2 + Prod project report "tasks are clear + executable"
- [ ] Day 7 AM: Tech lead sign-off on rollout

---

## 7. Blast Radius & Affected Systems

### Tier 1 (Direct Impact — Will Change)

- **`.specify/presets/nimbus-code-standards/templates/spec-template.md`**: Prepended header
- **`.specify/presets/nimbus-code-standards/templates/plan-template.md`**: Gates + ADL + release strategy sections
- **`.github/skills/speckit-tasks/templates/task-github-issue-template.md`**: Operational steps + cost reference
- **`/speckit-plan` skill**: Phase 0 research, Phase 1 design artifact generation
- **`/speckit-tasks` skill**: GHE issue publishing with hybrid guidance
- **All new features** created after merge (use new templates by default)

### Tier 2 (Indirect Impact — May Change)

- **GitHub Enterprise** (if custom parsers expect old task format)
- **CI/CD pipelines** (if they validate spec/plan/task structure; linter updated)
- **Developer tooling** (if they consume spec.md/plan.md; mostly read-only, low risk)
- **SPEC KIT COST** (external URL embedded; if URL breaks, automatic alert)

### Tier 3 (No Impact)

- **Existing features** (not regenerated; opt-in to pilot templates)
- **Infrastructure** (no deployment/resource changes)
- **Data stores** (no schema changes)

---

## 8. Cost & Effort Tracking

### Estimation vs. Reality (Feedback Loop)

| Phase | Estimated Tokens | Actual Tokens | Variance | Adjustment |
|---|---|---|---|---|
| Specify (Feature 005) | ~10k | ~9.2k | -8% | ✓ Within tolerance |
| Plan (Feature 005) | ~45–65k | TBD (after execution) | ? | Recorded in `tasks.md` |
| Tasks (Feature 005) | ~20–30k | TBD (after execution) | ? | Recorded in `tasks.md` |

**Use Case**: Compare actual vs. estimated for improving future token estimates.  
**Feedback Mechanism**: After `/speckit-tasks` completes, update reuse-catalog.yaml with real metrics.

---

## 9. Success Metrics

| Metric | Baseline | Target | Measurement |
|---|---|---|---|
| Spec generation time | ~2 min | <2 min | Time `/speckit-specify` to completion |
| Plan generation time | ~5 min | <8 min | Time `/speckit-plan` to completion (with Phase 0/1) |
| Task clarity (human perception) | N/A | >80% of devs report "clear + executable" | Pilot project survey |
| Cost estimate accuracy | N/A | 80–120% of actual | Compare estimated tokens vs. real in SPEC KIT COST |
| Feature adoption | 0 features | >50% of new features by Week 4 | Count features using hybrid templates |
| PR review time | ~1 hour | <45 min | Average time-to-approval for hybrid tasks vs. old tasks |
| Rollback activation count | N/A | 0 | Should never need to activate kill switch |

---

## 10. Post-Implementation Validation Checklist

- [ ] Pilot project 1 quickstart Steps 1–9 PASS
- [ ] Pilot project 2 quickstart Steps 1–9 PASS
- [ ] Production project quickstart Steps 1–9 PASS
- [ ] Human dev survey: "Did you understand the task without additional context?" → >80% Yes
- [ ] Cost tracking visible in SPEC KIT COST → no data loss
- [ ] Feature adoption tracking active (label `feature:hybrid-templates-v1` on issues)
- [ ] Rollback test executed successfully (verified templates revert on flag=false)
- [ ] Post-implementation ADR written (to `docs/adr/NNNN-hybrid-templates-design.md`)
- [ ] Reuse catalog updated with new pattern (tag: `hybrid-dev-templates`)

---

## References

- [Feature Spec](./spec.md) — Requirements & acceptance criteria
- [Implementation Plan](./plan.md) — Design decisions & gates
- [Module Dependency Graph](./graph.yaml) — Structured dependencies
- [Architecture Graphs](./graph.md) — Visual architecture diagrams
- [Task Contracts](./contracts/task-contract.md) — GHE issue format specification
- [Quickstart Guide](./quickstart.md) — E2E validation scenarios
