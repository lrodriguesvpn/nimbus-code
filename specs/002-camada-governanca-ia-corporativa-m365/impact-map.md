# Impact Map: Camada de Governanca IA Corporativa M365

## Purpose

Document the main risks, dependencies, and rollback posture for the documentation-only AI governance layer.

## Risks

| Risk | Impact | Mitigation | Rollback |
|---|---|---|---|
| Official-tool positioning remains ambiguous | Users may keep treating every AI tool as equally official | State the official tools explicitly and repeat the message in every related doc | Revert the unclear wording and restore the previous guidance |
| Nimbus aliases drift from the original Spec Kit commands | Compatibility confusion and support burden | Maintain a one-to-one alias map and note that the original commands remain valid | Remove or correct the alias mapping text |
| M365 governance is read as runtime enforcement | Stakeholders may expect tenant changes that are not in scope | Mark v1 as documentation-first and separate policy from enforcement | Roll back any wording that implies technical enforcement |
| Claude Enterprise / ChatGPT guidance diverges from the main constitution | Tool-specific policy fragmentation | Reuse the same constitution language and link back to the main policy | Revert the divergent document section |

## Dependencies

- Existing Nimbus-Code constitution and developer guidance
- Microsoft 365 Copilot governance documentation
- GitHub Copilot enterprise admin guidance
- Company agreement on official AI tooling

## Go / No-Go Criteria

- The constitution is singular and reusable across tools.
- The M365 guide clearly covers agent creation, sharing, and governance scope.
- The legacy-tools guide does not introduce a second policy.
- The Nimbus alias map preserves upstream command compatibility.

## Rollback Strategy

Because the feature is documentation-only, rollback is a PR revert that removes or corrects the affected markdown/YAML files. No runtime rollback or data migration is required.
