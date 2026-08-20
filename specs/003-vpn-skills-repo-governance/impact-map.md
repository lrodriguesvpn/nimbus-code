# VPN-SKILLS Impact Map

**Version**: 1.0  
**Feature**: 003-vpn-skills-repo-governance  
**Complexity**: S3 (Multiple modules, governance-critical integration)  
**Created**: 2026-08-12

---

## 1. Executive Summary

The VPN-SKILLS repository establishes centralized governance for reusable infrastructure skills across the organization. This is a **high-impact, medium-risk** initiative that affects downstream project initialization, CI/CD pipelines, and compliance workflows.

### Impact Scope

| Dimension | Impact | Priority |
|-----------|--------|----------|
| **Downstream Projects** | 50–100+ projects (current + future) | Critical |
| **Developer Workflow** | Changes initialization and validation pattern | High |
| **Compliance & Audit** | Centralized deprecation tracking and reporting | High |
| **Operations** | New SLA commitments for API availability | High |
| **Release Frequency** | Weekly skill updates expected | Medium |

### Go/No-Go Criteria

**MUST PASS before Phase 2 implementation**:
- [ ] API uptime SLO of 99.5% achievable with planned infrastructure
- [ ] Skill resolution latency <1 second (cached, <3 seconds uncached)
- [ ] No breaking changes to downstream bootstrap templates
- [ ] CLI tool distributed and working on Linux, macOS, Windows
- [ ] Compliance report generation working for test cohort (5 projects)

---

## 2. Risk Analysis

### 2.1 Critical Dependencies

#### Dependency 1: GitHub Infrastructure
**Risk**: GitHub outage or API rate limiting blocks skill publishing

| Factor | Details |
|--------|---------|
| **Dependency Level** | Critical |
| **Failure Mode** | GitHub API unavailable → skill indexing fails |
| **Impact on Users** | Projects cannot validate new skills; existing skills still work |
| **Recovery RTO** | 1 hour (manual cache reset + GitHub webhook replay) |
| **Mitigation** | 1. Cache skill list for 24 hours 2. Replay webhooks after recovery |
| **Fallback** | Serve stale cache until GitHub recovers |

#### Dependency 2: PostgreSQL Database
**Risk**: Database corruption, failover delays, capacity exhaustion

| Factor | Details |
|--------|---------|
| **Dependency Level** | Critical |
| **Failure Mode** | DB unavailable → API cannot serve requests |
| **Impact on Users** | Skill discovery and validation blocked (within SLA window) |
| **Recovery RTO** | 15–30 minutes (restore from backup or failover) |
| **Mitigation** | 1. Multi-AZ PostgreSQL (3 replicas) 2. Daily backups with 30-day retention 3. Automated failover 4. Connection pooling |
| **Fallback** | Serve read-only from stale cache for up to 1 hour |

#### Dependency 3: Redis Cache
**Risk**: Cache invalidation issues, stampedes, eviction

| Factor | Details |
|--------|---------|
| **Dependency Level** | High (non-critical, degrades to DB) |
| **Failure Mode** | Cache unavailable → all reads hit DB (slower) |
| **Impact on Users** | Validation latency increases from 0.5s to 2–3s |
| **Recovery RTO** | 5 minutes (pod restart or failover) |
| **Mitigation** | 1. Cluster mode with 3 replicas 2. Connection pooling 3. Cache invalidation strategy (webhook-triggered) |
| **Fallback** | Direct DB queries (acceptable degradation) |

#### Dependency 4: Kafka Message Queue
**Risk**: Message loss, lag, consumer failures

| Factor | Details |
|--------|---------|
| **Dependency Level** | Medium (async notifications, not blocking) |
| **Failure Mode** | Queue unavailable → compliance alerts delayed |
| **Impact on Users** | Notifications delayed up to 24 hours (batch retry) |
| **Recovery RTO** | 2 hours (consumer restart and replay from offset) |
| **Mitigation** | 1. 3 broker cluster with replication factor 3 2. Topic retention 7 days 3. Dead-letter queue for failures |
| **Fallback** | Fallback notifier sends email directly (slower, no Slack) |

### 2.2 Failure Modes and Cascades

#### Scenario A: API Server Outage (Single Replica)
**Trigger**: Crash, memory leak, or unplanned termination

```
API Pod crashes
  ↓
  Load balancer routes to next healthy pod (2–3s latency spike)
  ↓
  CLI/API requests queue up (brief, <1s median impact)
  ↓
  Auto-scaling triggers pod replacement (30–60s)
  ↓
  Recovery (user experiences <5s latency, no failures)
```

**Prevention**: Horizontal pod autoscaling (min 2, max 10); health checks every 10s

#### Scenario B: Database Failover (Full Replica Failure)
**Trigger**: Hardware failure, network partition, or maintenance

```
Primary DB node fails
  ↓
  Synchronous replica promoted to primary (~1s)
  ↓
  Connection pool reconnects (~500ms)
  ↓
  In-flight requests may fail; automatic retry from client
  ↓
  Recovery within SLA (no data loss due to multi-AZ replication)
```

**Prevention**: Multi-AZ RDS with automated failover; read replicas for query distribution

#### Scenario C: Skill Version Mismatch (Transitive Dependency)
**Trigger**: Incompatible versions in downstream manifest

```
Project declares: vpn-client-setup v2.1.3, certificate-authority v1.0.0
  ↓
  Validation passes (both exist)
  ↓
  Deployment: vpn-client-setup v2.1.3 requires certificate-authority >= 1.2.0
  ↓
  Runtime failure detected during integration test
  ↓
  Root cause: Transitive dependency not validated during manifest check
```

**Prevention**: Phase 1 enhancement: validate full transitive graph during manifest validation

#### Scenario D: Deprecated Skill Not Detected
**Trigger**: Compliance scanning missed in CI/CD

```
Project uses vpn-client-setup v2.0.5 (deprecated 2026-08-01, grace period 60 days)
  ↓
  Compliance report generated but not reviewed
  ↓
  Grace period expires (2026-10-01)
  ↓
  Skill support ends; project cannot troubleshoot issues
  ↓
  Incident escalates; operational burden increases
```

**Prevention**: 1. Mandatory compliance checks in CI/CD 2. Slack/email alerts at 80%, 50%, 20% of grace period remaining

---

## 3. Go/No-Go Gates

### Phase 1 Design Completion Gates

#### Gate 1: Technical Architecture Validated
**Criteria**:
- [ ] graph.yaml complete with all module dependencies
- [ ] graph.md Mermaid diagrams match architecture design
- [ ] Data model entity relationships verified
- [ ] API contracts (OpenAPI) fully specified
- [ ] CLI commands fully specified
- [ ] Estimated token cost for implementation: 18–24K tokens

**Owner**: Architecture Lead  
**Approval Required**: Yes

#### Gate 2: No Conflicting Dependencies with Bootstrap
**Criteria**:
- [ ] skills.yaml manifest does not conflict with existing bootstrap templates
- [ ] CLI installation method (curl | bash) aligns with bootstrap patterns
- [ ] No breaking changes to existing project init workflows
- [ ] Backward compatibility plan documented for legacy projects

**Owner**: Platform Lead  
**Approval Required**: Yes

#### Gate 3: SLO Targets Feasible
**Criteria**:
- [ ] API latency <1s (cached) achievable with proposed infrastructure
- [ ] API uptime 99.5% achievable with multi-AZ setup
- [ ] Skill resolution for 50+ projects completes in <5 seconds
- [ ] Compliance scanning <10 seconds for 10+ projects

**Owner**: Performance Engineer  
**Approval Required**: Yes

#### Gate 4: Compliance and Security Checks
**Criteria**:
- [ ] No secrets in spec, plan, or manifests
- [ ] Authentication strategy documented — GitHub App organizacional para escopo cross-repo/org (API → Repo, CLI → Repo, dashboard login); `GITHUB_TOKEN` nativo apenas para automações restritas ao próprio repositório VPN-SKILLS. Ver ADL-004 e specs/006-bootstrap-governance-hardening/spec.md (FR-004/FR-005).
- [ ] Network policies defined (ingress, egress, internal only for DB/cache)
- [ ] RBAC for skill publishing defined
- [ ] Data retention policy for compliance reports defined (30+ days)

**Owner**: Security Lead  
**Approval Required**: Yes

### Phase 2 Implementation Gates

#### Gate 5: Core API Deployed to Staging
**Criteria**:
- [ ] API server health checks passing
- [ ] Database connectivity verified
- [ ] Cache invalidation working end-to-end
- [ ] Load balancer routing to all replicas
- [ ] API latency benchmarks met in staging

**Owner**: DevOps Lead  
**Approval Required**: Yes before production deployment

#### Gate 6: CLI Tool Tested on All Platforms
**Criteria**:
- [ ] CLI builds and runs on Linux (x86, ARM)
- [ ] CLI builds and runs on macOS (Intel, Apple Silicon)
- [ ] CLI builds and runs on Windows (WSL, native)
- [ ] Installation via curl | bash works on all platforms
- [ ] All commands tested and documented

**Owner**: DevTools Lead  
**Approval Required**: Yes before public release

#### Gate 7: Test Cohort Compliance Checks Pass
**Criteria**:
- [ ] 5 pilot projects onboarded to skills.yaml
- [ ] Manifest validation working for all 5 projects
- [ ] Compliance reports generated and reviewed
- [ ] No unexpected incompatibilities detected
- [ ] Feedback from pilot projects incorporated

**Owner**: Platform Lead  
**Approval Required**: Yes before broad rollout

#### Gate 8: Runbooks and Incident Response Tested
**Criteria**:
- [ ] Database failover runbook tested (actual failover)
- [ ] API restart/rollback runbook tested
- [ ] Cache invalidation runbook tested
- [ ] Escalation paths documented
- [ ] On-call rotation established

**Owner**: SRE Lead  
**Approval Required**: Yes before production SLA

---

## 4. Rollback Plans

### 4.1 Component-Level Rollbacks

#### API Server Rollback
**Scenario**: Deploy introduces bugs or performance regression

**Rollback Procedure**:
1. Blue-green deployment: Route traffic back to previous version
2. Time to rollback: <2 minutes
3. Prerequisites: Helm chart with image tags pinned, previous replicas still running
4. Verification: Health checks passing, latency <1s, error rate <0.1%
5. Post-rollback: Investigate issue, fix, and redeploy

**Trigger**: Error rate > 1% or latency > 3s for 2 consecutive minutes

#### Database Schema Rollback
**Scenario**: Migration breaks existing queries

**Rollback Procedure**:
1. Restore database from backup (pre-migration snapshot)
2. Time to rollback: 5–15 minutes
3. Prerequisites: Daily backups, tested restore process
4. Data loss window: Up to 24 hours (acceptable for governance tooling)
5. Post-rollback: Verify schema consistency, re-apply migration with fixes

**Trigger**: Query failures after migration, manual approval required

#### CLI Tool Rollback
**Scenario**: CLI distribution breaks (installation or command syntax)

**Rollback Procedure**:
1. Update install script to serve previous version
2. Time to rollback: <10 minutes
3. Prerequisites: Previous version artifacts retained, checksums verified
4. Verification: Installation works, commands execute without errors
5. Post-rollback: Users manually run `vpn-skills update --version X.Y.Z`

**Trigger**: >10% installation failure rate, manual approval required

### 4.2 Feature-Level Rollbacks

#### Skills Deprecation Timeline Rollback
**Scenario**: Grace period was too short; projects can't migrate in time

**Rollback Procedure**:
1. Extend deprecation grace period by 30 days
2. Re-notify affected projects with updated timeline
3. Support period extended until new deadline
4. Publish new release notes and migration guide

**Trigger**: >5% of projects unable to migrate by grace period end

#### Breaking Change in Skill Version
**Scenario**: New skill version (v3.0) breaks downstream projects

**Rollback Procedure**:
1. Yank new version from catalog (mark as incompatible in database)
2. Direct users back to previous stable version (v2.1.3)
3. Open incident; investigate breaking change
4. Publish v3.0.1 patch or v3.1 with compatibility shim
5. Re-announce new version with migration guide

**Trigger**: >3 projects report critical failures with new version

---

## 5. Interdependencies with Downstream Projects

### 5.1 Bootstrap Template Integration

**Current State**: Skills copied directly into project templates  
**Future State**: Bootstrap templates reference VPN-SKILLS repository

**Dependency Chain**:
```
nimbus-code-spec-kit-template (bootstrap)
  ├─ References: skills.yaml schema from VPN-SKILLS
  ├─ CI/CD: Validates against VPN-SKILLS catalog
  └─ Initialization: vpn-skills init creates manifest

↓↓↓

Newly initialized projects
  ├─ Inherit skills.yaml from template
  ├─ Can add/modify/remove skills via edit
  ├─ Validate via vpn-skills validate (CI/CD gate)
  └─ Stay synchronized with VPN-SKILLS updates
```

**Risk**: If VPN-SKILLS API is unavailable, new project initialization fails at validation step

**Mitigation**:
- Skill list cached for 24 hours
- Fallback: Skip validation if cache stale (warn user)
- Bootstrap template includes offline validation rules (basic checks only)

### 5.2 CI/CD Pipeline Integration

**Requirement**: Every project's CI/CD must be able to validate skills.yaml

**Integration Points**:
1. GitHub Actions workflow: `.github/workflows/validate-skills.yml`
2. Pipeline runs on every push to `skills.yaml`
3. Fails the build if incompatibilities detected
4. Stores compliance report as artifact

**Risk**: CI/CD pipeline breaks if VPN-SKILLS API is slow or unreachable

**Mitigation**:
- Timeout: 30 seconds (fail-safe to "skip" if API hangs)
- Retry: 3 attempts with exponential backoff
- Fallback: Warn but don't fail if API unavailable (compliance checked on schedule separately)

### 5.3 Compliance and Audit Integration

**Requirement**: Audit trails must link skill usage to project versions

**Dependency Chain**:
```
Compliance Report (daily)
  ├─ Query all projects' skills.yaml manifests (from git)
  ├─ Resolve each skill version against VPN-SKILLS catalog
  ├─ Generate findings (deprecated, incompatible, etc.)
  ├─ Store findings in compliance database
  └─ Notify stakeholders (Slack, email)

↓↓↓

Project-level audit
  ├─ Link project commit hash to skills.yaml content
  ├─ Link skill version to compliance findings at that commit date
  └─ Enable root-cause analysis: "Why did project X fail on 2026-08-15?"
```

**Risk**: Compliance report cannot be generated if VPN-SKILLS API is down

**Mitigation**:
- Compliance engine retries up to 3 times over 1 hour
- If still failing, alert operator and use cached catalog (stale data)
- Report generated with ⚠️ "Incomplete scan" disclaimer

### 5.4 Downstream Breaking Changes

**Scenario**: A skill introduces a breaking change in major version bump

**Example**:
- vpn-client-setup v2.5.0 uses config file format A
- vpn-client-setup v3.0.0 requires config file format B (incompatible)
- Project declares `version: "^2.5.0"` (semver range allows 2.5 but not 3.0)

**Mitigation Strategy**:
1. **Advance warning** (60 days): Publish RFC for breaking change; solicit feedback
2. **Pre-release** (30 days): Release v3.0.0-beta on alternate branch; allow testing
3. **Deprecate old version** (grace period): Mark v2.5.0 as deprecated, start grace period (60 days)
4. **Coordinate releases**: Publish v3.0.0-stable with migration guide
5. **Monitor adoption**: Track projects pinned to v2.x; reach out to outliers at 80%, 50%, 20% of grace period

**Downstream Projects' Obligations**:
- Monitor deprecation warnings in compliance reports
- Test new versions in dev/staging before upgrading production
- Update skills.yaml with new version range and commit/PR
- Coordinate release with VPN-SKILLS roadmap (when possible)

---

## 6. SLO Definitions

### 6.1 API Availability

**SLO**: 99.5% uptime (monthly)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Availability | 99.5% | Requests succeeding / total requests |
| Error Rate | <0.5% | 5xx errors + timeouts / total |
| Downtime Budget | ~3.6 hours/month | Time allowed for maintenance + incidents |

**Alerting**:
- Critical: Error rate >1% for 2 min
- Warning: Error rate >0.5% for 5 min
- Info: Any observed degradation logged

### 6.2 API Latency

**SLO**: P95 latency <1 second (cached), <3 seconds (uncached)

| Endpoint | P50 | P95 | P99 | Notes |
|----------|-----|-----|-----|-------|
| GET /skills | 50ms | 200ms | 500ms | Cached from Redis |
| GET /skills/:id | 100ms | 300ms | 800ms | Cached from Redis |
| POST /validate | 500ms | 1s | 2s | DB + transitive resolution |
| GET /compliance/:projectId | 1s | 3s | 5s | Full scan of all dependencies |

**Alerting**:
- P95 latency >2s (baseline + 100%) for 5 min
- P99 latency >5s for 5 min
- Spike detected (>2x baseline)

### 6.3 Database Performance

**SLO**: 99.9% uptime, <100ms query latency (p95)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Uptime | 99.9% | DB accepting connections / time period |
| Query Latency (p95) | <100ms | Read queries on hot tables (skills, versions) |
| Replication Lag | <1s | Primary-to-replica lag |
| Backup Success | 100% | Daily backups completed without error |

**Alerting**:
- DB unreachable for >30s
- Replication lag >10s
- Backup failure for 2 consecutive days

### 6.4 Compliance Report SLO

**SLO**: Reports generated within 4 hours of scheduled scan; 99% accuracy

| Metric | Target | Measurement |
|--------|--------|-------------|
| Scan Frequency | Daily | Once per 24 hours |
| Completion Time | <4 hours | Time from scan start to report available |
| Accuracy | 99% | False positives + false negatives <1% |

**Alerting**:
- Report not generated by T+4 hours
- Audit report count mismatch >5%

---

## 7. Operational Readiness Checklist

### Before Production Deployment

- [ ] **Monitoring & Observability**
  - [ ] Prometheus metrics exposed for all services
  - [ ] ELK stack (or equivalent) collecting logs
  - [ ] Distributed tracing (X-Trace-Id header) implemented
  - [ ] Dashboards created for API, DB, cache, queue
  
- [ ] **Incident Response**
  - [ ] On-call rotation established (primary + backup)
  - [ ] PagerDuty/Opsgenie integration configured
  - [ ] Runbooks written and tested for all components
  - [ ] Escalation matrix defined
  
- [ ] **Security**
  - [ ] Network policies deployed (K8s NetworkPolicy)
  - [ ] SSL/TLS certificates provisioned (auto-renewal configured)
  - [ ] API authentication working — token de instalação de GitHub App (server-to-server) e user-to-server OAuth do mesmo App (dashboard); nenhum PAT clássico. Ver ADL-004.
  - [ ] Secrets management (HashiCorp Vault) set up
  
- [ ] **Disaster Recovery**
  - [ ] Database backups automated and tested (restore practice run)
  - [ ] Failover tested (manual DB failover executed, recovery timed)
  - [ ] Rollback procedures documented and rehearsed
  
- [ ] **Documentation**
  - [ ] Architecture Decision Records (ADRs) published
  - [ ] API documentation complete and accessible
  - [ ] CLI help text and man pages available
  - [ ] Operational procedures documented
  
- [ ] **Testing**
  - [ ] Load testing completed (1000 RPS, 100 concurrent projects)
  - [ ] Chaos engineering executed (inject failures, verify resilience)
  - [ ] Integration testing with pilot projects completed
  - [ ] Smoke tests defined for CI/CD

---

## 8. Risk Summary Table

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| GitHub API unavailable | Low | High | Cache skills list 24h; replay webhooks | DevOps |
| Database failover delay | Low | High | Multi-AZ setup; automated failover | DBAs |
| Incompatible skill version deployed | Medium | High | Transitive dependency validation; testing | Platform |
| Compliance scanning fails | Medium | Medium | Retry logic; fallback to stale cache | SRE |
| CLI installation broken on some platform | Low | Medium | Test on Linux/macOS/Windows; CI/CD gates | DevTools |
| Deprecated skill grace period too short | Medium | Medium | Extend grace period; monitor adoption | Product |
| Circular dependency in skills | Low | Medium | Detect during validation; prevent merge | Platform |

---

## 9. Go/No-Go Decision Framework

### Recommendation for Phase 2 Execution

**Overall Readiness**: 🟡 CONDITIONAL GO

**Conditions for Approval**:
1. ✅ All design gates (1–4) approved by respective owners
2. ✅ Risk mitigation strategies funded and scheduled
3. ✅ SLO targets validated with infrastructure team
4. ✅ Runbooks drafted and assigned for review
5. ✅ On-call rotation and escalation paths confirmed

**Next Steps**:
- Complete Phase 0 research (resolve NEEDS CLARIFICATION items in plan.md)
- Execute Phase 1 design artifacts validation (gates 1–4)
- Schedule Phase 2 kickoff after gate approvals
- Establish monitoring and alerting baseline (pre-implementation)
- Brief all downstream project teams on timeline and integration points

---

## References

- **graph.yaml**: Module topology and dependencies
- **graph.md**: Dependency diagrams and visualizations
- **data-model.md**: Database schema and entity relationships
- **plan.md**: Architecture Decision Log and Phase 0 research agenda
- **spec.md**: Feature requirements and acceptance criteria

