# k-app

Purpose of this repo is to explore container development dev cycle
from the perspective of a windows desktop user.

The larger context is an app that is intended for eventual enterprise
deployment, using CI that is not present here, but inferred
as already existing.

The goal is to give the dev fast local turn-around of development without waiting 1-2 minutes for typical CI/CD cycles after every commit.

This workspace was developed with ms-windows in mind, but theoretically it should
work on linux as well.

## Assumptions
It is possible to develop using other methods. 
The instructions below assume you are developing under MS-Windows with the following tools:

* Rancher Desktop installed
* VS Code
  * Kubernetes extension installed
  * "Task Buttons" extension installed
* "DevSpace" installed ( Can use [install-devspace.ps1](install-devspace.ps1) )


## Test app

`app/main.py` is a tiny stdlib-only Python HTTP service (port 8080):
`/` returns a JSON greeting/version/hostname, `/healthz` and `/readyz` are probes.
Config via env: `GREETING`, `APP_VERSION`, `PORT`, `LOG_LEVEL`.

Run it from the buttons on the VS Code status bar (bottom left of the window frame). 

(  ▶ Dev, 🌐 Open, ()UI, ()Deploy and 🗑 Remove )

| Button | What it does |
|---|---|
| **Continuous Deploy** | Builds, deploys and syncs `app/` into the cluster, with the app on http://k-app.localhost (and http://localhost:8080). Saving a file in `app/` copies it into the running container and restarts the app. Edits to the `Dockerfile` or `k8s/` are not picked up until you stop and restart it. What runs is the first build plus synced files, not a fresh image, so check with **Deploy Once** before trusting a result. Stop with the trash icon on its terminal panel. |
| **Deploy Once** | One-off build and deploy, as CI would do. No sync. |
| **Open App** | Opens http://k-app.localhost, after either deploy button. |
| **DevSpace UI** | Opens DevSpace's web page: logs, a shell in the pod, ports. |
| **Remove** | Deletes k-app from the cluster. |

Everything goes into the `k-app` namespace. The buttons and tasks live in `.vscode/`.

Layout: `Dockerfile` (non-root image), `k8s/` (plain manifests CI would apply, including an Ingress on `k-app.localhost` via Rancher Desktop's Traefik),
`devspace.yaml` (local dev loop only).
