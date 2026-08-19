# Release and Rollback

Release uses canary rollout with feature flag `platform-preset-cmdb-governance`.

Rollback triggers:

- CMDB consistency regression;
- discovery failure above threshold;
- missing 24h refresh window;
- critical compliance findings not handled by exception flow.
