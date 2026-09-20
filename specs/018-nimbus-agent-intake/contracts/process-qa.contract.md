# Contract: Process Q&A

Input is a question and optional bounded context. Output contains `answer`,
`confidence`, `sources[]`, `scope_status` and, when needed, a
`clarification_question`.

The answer must cite central artifacts. If sources conflict or confidence is
below threshold, `scope_status=needs_clarification` and no process rule is
invented.

