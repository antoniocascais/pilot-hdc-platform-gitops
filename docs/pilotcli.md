# pilotcli Deployment

JupyterHub notebooks expect the `pilotcli` binary at `/opt/shared/pilotcli`. It lives on the per-project `shared-tools` PVC (RWX NFS), not in the notebook image. [`scripts/update-pilot-cli.sh`](../scripts/update-pilot-cli.sh) downloads a release from [`PilotDataPlatform/cli`](https://github.com/PilotDataPlatform/cli) and copies it into every `project-*` namespace's `shared-tools` PVC.

## When to run

- After creating a new project namespace. Wave 11 `project-resources` provisions the PVC but leaves it empty.
- On every new `pilotcli` release. Bump `PILOTCLI_VERSION` in the script, commit, run per cluster.

## Prerequisites

- `kubectl` context on the target cluster.
- Each `project-*` namespace needs:
  - `shared-tools` PVC (RWX, `nfs-client`) from `project-resources`
  - `docker-registry-secret` from `registry-secrets`
- Local: `curl`, `jq`, `kubectl`.

## Usage

```bash
./scripts/update-pilot-cli.sh            # dev (default)
ENV=prod ./scripts/update-pilot-cli.sh   # prod
```

Project namespaces come from `clusters/$ENV/workbench/projects/*.yaml`.

## Mechanics

For each namespace: apply a busybox Deployment mounting `shared-tools` RW, `kubectl cp` the binary to `/opt/shared/pilotcli`, delete the Deployment. The binary persists on NFS. Notebooks mount `shared-tools` read-only and pick it up on next spawn.

## Caveats

- Not GitOps-managed. Record each run in the relevant ctask.
- Release tag format: `<version>-hdc` (e.g. `2.2.7-hdc`).
- Processes one namespace at a time; runtime scales with project count.
