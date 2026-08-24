# Data Model: AgentRC Brownfield Evaluation

## Entities

### Capability

Represents a capability declared by AgentRC or already present in the current
Nimbus Code flow.

**Fields**
- `name`: short label for the capability
- `source`: `AgentRC` or `Nimbus Code`
- `description`: plain-language summary
- `category`: measure, generate, maintain, governance, validation

### EvidenceSource

Represents a source used to support the comparison.

**Fields**
- `title`
- `type`: public docs, internal doc, artifact, observation
- `location`
- `reliability_notes`

### Conflict

Represents overlap, duplication or incompatibility between AgentRC and the
current flow.

**Fields**
- `capability_name`
- `conflict_type`: duplicate, overlap, incompatible, gap
- `impact`
- `severity`

### Recommendation

Represents the final decision for the evaluation.

**Fields**
- `decision`: adopt, adopt-with-restrictions, reject
- `reason_summary`
- `pilot_scope`
- `exit_criteria`

### ComparisonMatrix

Represents the final comparison artifact.

**Fields**
- `feature_name`
- `capabilities`: list of Capability comparisons
- `conflicts`: list of Conflict records
- `recommendation`: one Recommendation

## Relationships

- A `ComparisonMatrix` contains many `Capability` comparisons
- A `Capability` may reference one or more `EvidenceSource` entries
- A `Capability` may produce zero or more `Conflict` records
- A `ComparisonMatrix` has exactly one `Recommendation`

## Validation Rules

- Every capability included in the matrix must have an evidence source
- Every conflict must state whether it is a duplicate, overlap or incompatibility
- The recommendation must be unique and actionable
- If pilot scope exists, exit criteria must be defined

