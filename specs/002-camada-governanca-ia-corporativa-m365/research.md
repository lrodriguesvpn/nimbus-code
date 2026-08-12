# Research Notes: Camada de Governanca IA Corporativa M365

## Decision 1: Basear a governança do M365 nos controles oficiais do Microsoft 365 admin center, Copilot Control System e Microsoft Purview

**Decision**: The plan will document governance around the Microsoft 365 admin center, Copilot Control System, and Microsoft Purview as the official control surfaces for agents and Copilot experiences.

**Rationale**: Microsoft documents that agent governance includes policies for access, sharing, publishing, inventory, blocking, and lifecycle controls, and that Copilot/agent data remains subject to Microsoft 365 permissions, DLP, retention, and audit capabilities.

**Alternatives considered**:
- Treat the feature as a generic policy doc with no Microsoft-specific control references.
- Center the guidance only on Copilot Studio or only on the agent builder experience.

## Decision 2: Position Microsoft 365 Copilot as the official productivity tool and GitHub Enterprise Copilot as the official engineering tool

**Decision**: The plan will state that Microsoft Copilot is the official AI family for business productivity and GitHub Enterprise Copilot is the official AI family for engineering workflows.

**Rationale**: The feature request requires a clear company standard. Microsoft documentation also shows that Microsoft 365 Copilot and GitHub Copilot each have mature enterprise admin controls, which supports a formal official-tool stance.

**Alternatives considered**:
- Allow multiple tools to be equally official.
- Keep the official-tool position implicit and only document allowed use.

## Decision 3: Keep Claude Enterprise and ChatGPT as guided legacy/transition tools under the same constitution

**Decision**: The plan will produce a portable guide that shows how the same corporate constitution applies to Claude Enterprise and ChatGPT users, rather than creating separate policies per tool.

**Rationale**: This avoids policy fragmentation while supporting users who still depend on those tools.

**Alternatives considered**:
- Write separate constitutions per tool.
- Exclude legacy tools from the governance layer entirely.

## Decision 4: Treat Nimbus command names as a naming layer only

**Decision**: The plan will document Nimbus aliases for the Spec Kit commands while preserving the original command names.

**Rationale**: The request explicitly asks for compatibility with upstream. A naming layer avoids breaking existing behavior and keeps the path open for future upstream updates.

**Alternatives considered**:
- Rename the original commands.
- Fork the command behavior.
- Require users to learn only the upstream names.

## Sources consulted

- [Agents admin guide for Microsoft 365](https://learn.microsoft.com/microsoft-365/copilot/agent-essentials/m365-agents-admin-guide#set-agent-policies)
- [Data, privacy, and security considerations for extending Microsoft 365 Copilot](https://learn.microsoft.com/microsoft-365/copilot/extensibility/data-privacy-security#governance-and-admin-controls-for-agent-sharing)
- [How data is protected and audited in Microsoft 365 and Microsoft 365 Copilot](https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-architecture-data-protection-auditing)
- [Data, Privacy, and Security for Microsoft 365 Copilot](https://learn.microsoft.com/microsoft-365/copilot/microsoft-365-copilot-privacy)
