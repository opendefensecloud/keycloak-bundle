# ADR-003: OCM Packaging Strategy

**Status:** Accepted  
**Date:** 2026-01-31  
**Decision Makers:** Project Team, Customer

## Context

The solution must be packaged as an OCM (Open Component Model) component for deployment in pCloudBw environments. OCM provides a standardized way to bundle and distribute software components.

## Decision

Package the Keycloak solution as a single OCM component containing:
- Container images (Keycloak, PostgreSQL, Operator)
- Helm charts for operators
- KRO ResourceGraphDefinition
- Manifests and examples
- Documentation

## Rationale

- Customer requirement (pCloudBw Blueprint)
- Enables air-gapped deployment
- Version tracking for all components
- Reproducible deployments
- Transfer between registries

## Consequences

### Positive
- Single deployable unit
- All dependencies bundled
- Works in disconnected environments
- Integrates with KRO for instantiation

### Negative  
- OCM tooling learning curve
- Component descriptor maintenance
- Image mirroring complexity

## Structure

```
component-descriptor.yaml
├── resources:
│   ├── keycloak-image (ociImage)
│   ├── postgres-image (ociImage)
│   ├── operator-image (ociImage)
│   ├── operator-chart (helmChart)
│   ├── keycloak-instance-rgd (blueprint)
│   ├── manifests (directory)
│   └── docs (directory)
```

## Implementation Notes

For Milestone 1:
- Create basic component-descriptor.yaml
- Reference external images (not yet mirrored)
- Include RGD for basic instantiation
- Validate OCM package structure
