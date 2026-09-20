# Contract: Session Cost Event

```json
{
  "session_id": "sess-abc123",
  "feature_id": "010-controle-de-custos",
  "model": "claude-sonnet-4.6",
  "input_tokens": 40000,
  "output_tokens": 12000,
  "occurred_at": "2026-08-18T17:00:00Z"
}
```

`session_id`, `feature_id`, `model`, token counts e `occurred_at` UTC são
obrigatórios. Reprocessamento do mesmo evento é idempotente. Conteúdo de prompt
e PII são proibidos. O coletor cria um `CostRecord` imutável com
`dimension=tokens`.

