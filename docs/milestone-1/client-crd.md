# KeycloakClient CRD

Custom Resource for managing Keycloak clients declaratively.

## Installation

```bash
kubectl apply -f charts/keycloak-client-operator/crds/keycloakclient-crd.yaml
```

## Usage

```yaml
apiVersion: keycloak.bwi.de/v1alpha1
kind: KeycloakClient
metadata:
  name: my-app
  namespace: keycloak-dev
spec:
  clientId: my-application
  name: My Application
  enabled: true
  protocol: openid-connect
  publicClient: false
  redirectUris:
    - "http://localhost:3000/*"
  webOrigins:
    - "http://localhost:3000"
```

## Spec Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| clientId | string | yes | - | Client ID in Keycloak |
| name | string | no | - | Display name |
| description | string | no | - | Description |
| enabled | boolean | no | true | Client enabled |
| protocol | string | no | openid-connect | openid-connect or saml |
| publicClient | boolean | no | false | No secret required |
| redirectUris | []string | no | - | Valid redirect URIs |
| webOrigins | []string | no | - | CORS origins |

## Status Fields

| Field | Description |
|-------|-------------|
| ready | Sync successful |
| keycloakId | Internal Keycloak UUID |
| lastSyncTime | Last sync timestamp |
| message | Status message |

## Examples

See `examples/client-example.yaml` and `examples/client-public.yaml`.

## Notes

- CRD is namespace-scoped
- Deploy client in same namespace as Keycloak instance
- Operator must be running for sync to work

**TODO:** Operator implementation in progress.
