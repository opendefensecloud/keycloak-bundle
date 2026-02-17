# Declarative Keycloak Configuration

This document documents the decision to use a **Custom Operator** for the Open Defense Cloud project and compares it against other evaluated approaches.

## Problem

A deployed Keycloak instance is an empty IAM server. Configuration (Realms, Clients, Users) must be:

- **Declarative**: Defined as K8s Custom Resources (CRDs), version-controlled in Git.
- **Continuously Reconciled**: Drift from the desired state must be detected and corrected.
- **Air-gap Compatible**: All artifacts must fit into a single OCM component.
- **Open Source**: Permissive license (Apache 2.0).

## Approaches Evaluated

The following approaches were evaluated against the project requirements.

### 1. Thin Custom Operator (Selected)

Build a minimal Operator (Bash/Helm or Go) that directly watches specific CRDs (`KeycloakClient`) and reconciles them against the Keycloak Admin API.

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

| Feature | Custom Operator | config-cli Wrapper | Crossplane | Hybrid (Selected) |
| :--- | :---: | :---: | :---: | :---: |
| **K8s CRDs** | ✅ Custom | ✅ Custom | ✅ Native | ✅ Custom |
| **Reconciliation** | ✅ Continuous | 🟡 Triggered | ✅ Continuous | ✅ Mixed |
| **Air-gap Fit** | ✅ Excellent | ✅ Good | ⚠️ Heavy | ✅ Good |
| **Footprint** | 🟢 Low | 🟢 Low | 🔴 High | 🟢 Low |

## Selected Strategy: Option 5 (Hybrid) [Provisional]

**The project tentatively selects Option 5: A minimal Custom Operator for `KeycloakClient`, combined with `keycloak-config-cli` for Realm configuration.**

> [!NOTE]
> **Status: PROVISIONAL / OPEN**
> This strategy is the current working assumption but remains subject to further analysis and team agreement. The implementation starts with the **Custom Operator for KeycloakClient** as a low-risk proof-of-concept (POC). The decision to expand to a full Hybrid model or pivot to Option 2 (Pure Config-CLI Wrapper) will be made based on the operational experience with the POC.

**Rationale:**
1.  **KeycloakClient (High Frequency)**: Clients change often (App deployments). A continuous reconciliation loop (Custom Operator) is critical here for GitOps.
2.  **KeycloakRealm (Low Frequency)**: Realms are complex and stable. Wrapping the battle-tested `keycloak-config-cli` avoids re-implementing 100+ resource types.

### Fallback Strategy

If maintenance of the Custom Operator becomes too high, the recommended pivot is to fully embrace **Option 2 (config-cli Wrapper)** for all resources.

## Architecture

The CRD hierarchy follows the Keycloak domain model, scoped to Namespaces:

```text
KeycloakInstance (Cluster/Namespace)
└── KeycloakRealm (Namespace)
    ├── KeycloakClient       <-- Implemented (Custom Operator)
    ├── KeycloakUser         <-- Planned (Config-CLI)
    ├── KeycloakGroup        <-- Planned (Config-CLI)
    └── KeycloakClientScope  <-- Planned (Config-CLI)
```

For technical details on the CRD schema and usage, see [USAGE-CONCEPT.md](USAGE-CONCEPT.md).

## Decision Record

### CRD Model for Keycloak Configuration (2026-01-31)

*Decision: Implement namespace-scoped CRDs for Keycloak resources.*
Declarative configuration is a core requirement. Namespace-scoped CRDs align with the multi-instance isolation model (see [ARCHITECTURE.md](ARCHITECTURE.md)) and enable GitOps workflows.

### Declarative Configuration Strategy (2026-02-11)

*Decision: Start with KeycloakClient (Custom Operator) while evaluating the full Hybrid approach.*
Five approaches were evaluated. `keycloak-config-cli` lacks continuous reconciliation for high-frequency changes. A pure Custom Operator is too expensive to maintain for the full scope.
**Conclusion**: The **Hybrid approach (Option 5)** is selected as the target architecture, starting with `KeycloakClient` as the first milestone. This decision is kept **open** to allow pivoting based on POC results.

## Related Documents

| Topic | Document |
|-------|----------|
| Architecture Overview | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Technical Usage Guide | [USAGE-CONCEPT.md](USAGE-CONCEPT.md) |
