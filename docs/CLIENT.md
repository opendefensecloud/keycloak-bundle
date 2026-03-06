# Declarative Keycloak Configuration

This document records the architectural decision for declarative Keycloak configuration in the Open Defense Cloud project and compares the approaches that were evaluated.

## Problem

A deployed Keycloak instance is an empty IAM server. Configuration (Realms, Clients, Users) must be:

- **Declarative**: Defined as K8s Custom Resources (CRDs), version-controlled in Git.
- **Continuously Reconciled**: Drift from the desired state must be detected and corrected.
- **Air-gap Compatible**: All artifacts must fit into a single OCM component.
- **Open Source**: Permissive license (Apache 2.0).

## Approaches Evaluated

### 1. Thin Custom Operator

Build a minimal Operator (Bash/Helm or Go) that directly watches specific CRDs and reconciles them against the Keycloak Admin API.

*   **Pros**: Lightest footprint (~20MB), full control, zero external dependencies.
*   **Cons**: Maintenance burden (we own the integration).

### 2. keycloak-config-cli (Wrapped)

Use [keycloak-config-cli](https://github.com/adorsys/keycloak-config-cli) as the engine, triggered by a thin K8s controller.

*   **Pros**: 100% Feature coverage, low maintenance.
*   **Cons**: "Run-to-completion" (Job) instead of continuous watch; potential temporary drift.

### 3. Crossplane Provider

Use `crossplane-contrib/provider-keycloak`.

*   **Pros**: Standard "Infrastructure as Data" model.
*   **Cons**: **Heavy footprint** (>500MB runtime, 100+ CRDs). Viable only if Crossplane is already present.

### 4. Official Keycloak Operator (RealmImport)

Use the official `KeycloakRealmImport` CR.

*   **Pros**: Official supported.
*   **Cons**: **Create-only**. No updates, no drift correction. Disqualified for Day-2 operations.

### 5. Hybrid Operator (Custom + Config-CLI)

Combine **Option 1 (Custom Operator)** for high-frequency resources (Clients) and **Option 2 (Config-CLI Wrapper)** for complex, stable resources (Realms/Users).

*   **Pros**: Best of both worlds: Speed for dev-facing resources, stability for admin-facing resources.
*   **Cons**: Dual maintenance path (two controllers or logic branches).

## Comparison Matrix

| Feature | Custom Operator | config-cli Wrapper | Crossplane | Hybrid |
| :--- | :---: | :---: | :---: | :---: |
| **K8s CRDs** | ✅ Custom | ✅ Custom | ✅ Native | ✅ Custom |
| **Reconciliation** | ✅ Continuous | 🟡 Triggered | ✅ Continuous | ✅ Mixed |
| **Air-gap Fit** | ✅ Excellent | ✅ Good | ⚠️ Heavy | ✅ Good |
| **Footprint** | 🟢 Low | 🟢 Low | 🔴 High | 🟢 Low |

## Architecture

The CRD hierarchy follows the Keycloak domain model, scoped to Namespaces:

```text
KeycloakInstance (via KRO)
└── KeycloakRealm
    ├── KeycloakClient
    ├── KeycloakUser
    ├── KeycloakGroup
    └── KeycloakClientScope
```

For usage details and examples, see [USAGE.md](USAGE.md).

## Decision Record

### CRD Model for Keycloak Configuration (2026-01-31)

*Decision: Implement namespace-scoped CRDs for Keycloak resources.*

Declarative configuration is a core requirement. Namespace-scoped CRDs align with the multi-instance isolation model (see [ARCHITECTURE.md](ARCHITECTURE.md)) and enable GitOps workflows.

### Declarative Configuration Strategy — Initial (2026-02-11)

*Decision: Start with KeycloakClient (Custom Operator) while evaluating the full Hybrid approach.*

Five approaches were evaluated. `keycloak-config-cli` lacks continuous reconciliation for high-frequency changes. A pure Custom Operator is too expensive to maintain for the full scope.

The Hybrid approach (Option 5) was selected as the working assumption, starting with `KeycloakClient` as a proof-of-concept. The decision was kept open pending operational experience.

### Declarative Configuration Strategy — Final (2026-02-24)

*Decision: Extend the Custom Operator to cover all resource types. The Hybrid approach and Config-CLI are dropped.*

POC experience with `KeycloakClient` confirmed that the Bash-based operator pattern is straightforward to extend. The Keycloak Admin API for Realm, User, Group, and ClientScope is not significantly more complex than for Client. Extending the existing operator avoids introducing a second tool (`keycloak-config-cli`) into the OCM component, keeps the OCM footprint minimal (one operator image), eliminates dual maintenance paths, and provides continuous reconciliation for all resource types — not just clients.

From `v0.2.0`, the single Custom Operator manages the full CRD hierarchy.

## Related Documents

| Topic | Document |
|---|---|
| Architecture Overview | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Technical Usage Guide | [USAGE.md](USAGE.md) |
