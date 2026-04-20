# Docs

Operational scripts and runbooks for the HDC platform.

## Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| [validate-postgresql.sh](validate-postgresql.sh) | Validates PostgreSQL init-job results: databases, ownership, users, schemas, extensions, cron jobs, privileges, and connectivity | `./docs/validate-postgresql.sh [namespace] [pod]` |

## Runbooks

| Runbook | Covers |
|---------|--------|
| [pilotcli.md](pilotcli.md) | Deploying the `pilotcli` binary to JupyterHub `shared-tools` PVC across project namespaces |
| [vault-secrets.md](vault-secrets.md) | Provisioning Vault secrets after bootstrap |
