# argo-config

GitOps source of truth for a Talos Kubernetes cluster managed by ArgoCD and Kargo.

This repository holds **application configuration only** — Helm values, raw manifests, and local charts. It does not contain the deployment pipeline logic (chart versions, image tags, promotion targets). Those live in [`kargo-config`](https://github.com/rhoades-brown/kargo-config), which is kept separate to prevent Kargo promotions from triggering ArgoCD feedback loops.

---

## How it works

```
kargo-config/configs/*.yaml          argo-config/app-loader
        │                                     │
        │  ApplicationSet reads configs       │  Helm chart renders ArgoCD Application
        └──────────────┐                      │  from values supplied by kargo-config
                       ▼                      │
              ArgoCD managed-apps  ───────────┘
              ApplicationSet
                       │
                       ▼  one Application per app
              {name}-loader Application
                       │
            ┌──────────┴──────────┐
            │                     │
     chart/helm source      argo-config
     (version from          valuesfiles/ + manifests/
      kargo-config)         (config from argo-config)
```

1. **Bootstrap** — the `apps/` Helm chart is deployed once (manually or via Talosdeploy). It creates two ArgoCD resources:
   - `managed-apps` **ApplicationSet** — generates one `{name}-loader` Application for every `configs/*.yaml` file in `kargo-config`.
   - `kargo-apps` **Application** — deploys the Kargo ApplicationSet from `kargo-config/apps/`, which manages Kargo CRDs for each app.

2. **Per-app Applications** — each `{name}-loader` Application rendered by `app-loader` pulls its chart/image version from `kargo-config/configs/{name}.yaml` and its values/manifests from this repo (`argo-config`).

3. **Kargo writes to `kargo-config`, not here** — when Kargo promotes a new chart or image version it commits to `kargo-config`. ArgoCD then picks up the changed `configs/{name}.yaml` and redeploys only that app. Nothing in `argo-config` changes during a promotion, so no feedback loop is triggered.

---

## Directory structure

```
argo-config/
├── apps/                        Bootstrap Helm chart (deploy once)
│   └── templates/
│       ├── applicationset.yaml  Generates {name}-loader Applications from kargo-config/configs/
│       ├── kargo-apps.yaml      Deploys kargo-config/apps/ (Kargo CRD ApplicationSet)
│       └── nvidiadevicecclass.yaml
│
├── app-loader/                  Helm chart – template for every managed Application
│   └── templates/
│       └── application.yaml    Renders an ArgoCD Application; supports multiple source types:
│                                 • upstream Helm chart  (chart.repoURL set)
│                                 • local Helm chart     (helmPath set)
│                                 • raw git source       (gitSource.repoURL set)
│                               Always attaches valuesFile and/or manifestsPath from argo-config.
│
├── valuesfiles/                 Per-app Helm values overrides
│   ├── cert-manager.yaml
│   ├── cilium.yaml
│   ├── immich.yaml
│   ├── jellyfin.yaml
│   ├── penpot.yaml
│   └── ...
│
├── manifests/                   Per-app raw Kubernetes manifests (applied alongside the Helm chart)
│   ├── immich/                  e.g. CNPG Cluster, Database, ExternalSecrets
│   ├── penpot/
│   ├── ingress-nginx/
│   └── ...
│
└── helm/                        Local Helm charts for custom/bespoke apps
    ├── omni-tools/
    ├── paperless-ngx/
    └── whoami/
```

---

## app-loader value keys

These keys are set in `kargo-config/configs/{name}.yaml` and consumed by `app-loader`:

| Key | Purpose |
|-----|---------|
| `name` | App name; used as the ArgoCD Application name and namespace default |
| `namespace` | Target Kubernetes namespace |
| `gitRepo` | Git repo containing values/manifests (`argo-config`) |
| `targetRevision` | Git tag/branch for `gitRepo`; updated by Kargo on each promotion |
| `chart.repoURL` | Upstream Helm repo URL |
| `chart.name` | Chart name |
| `chart.version` | Chart version; updated by Kargo on each promotion |
| `valuesFile` | Path to values file in `argo-config` (e.g. `valuesfiles/myapp.yaml`) |
| `manifestsPath` | Path to raw manifests directory in `argo-config` (e.g. `manifests/myapp`) |
| `helmPath` | Path to a local Helm chart in `argo-config` (instead of upstream chart) |
| `gitSource.repoURL` | Alternative: deploy directly from a third-party git repo |
| `extraSyncOptions` | Additional ArgoCD sync options (e.g. `ServerSideApply=true`) |
| `ignoreDifferences` | ArgoCD ignoreDifferences rules |
| `kargo.enabled` | Whether this app has a Kargo pipeline; adds the authorized-stage annotation |
| `kargo.project` | Kargo project name (namespace for Kargo CRDs) |

---

## Secrets

Secrets are managed by [External Secrets Operator](https://external-secrets.io) pulling from [Pulumi ESC](https://www.pulumi.com/product/esc/). Each app's `manifests/{name}/` directory may contain an `ExternalSecret` referencing the `pulumi-secret-store` ClusterSecretStore.

No secrets are stored in this repository.
