# k-app

The purpose of this repo is to showcase a sample container development dev cycle
from the perspective of a windows desktop user.

The larger context is a containerized app that is intended for eventual enterprise
deployment, using CI that you would add to suit your own environments.
The key principle is that the workflow showcased here will not interfere with any kind of enterprise CI
that would also be present in the repo.

The goal is to give a developer fast local turn-around of development without waiting 1-2 minutes for typical CI/CD cycles after every commit.

This workspace was developed on ms-windows, but theoretically it should
work on linux as well.

## Assumptions
It is possible to develop using other methods. 
The instructions below assume you are developing with the following tools:

* Rancher Desktop installed
* VS Code
  * Kubernetes extension installed
  * "Task Buttons" extension installed
* [DevSpace](https://www.devspace.sh/) installed ( Can use [install-devspace.ps1](install-devspace.ps1) on Windows, or [install-devspace.sh](install-devspace.sh) on Linux )


## The sample app

`app/main.py` is a tiny stdlib-only Python HTTP service that runs on port 8080. The top level will return a simple JSON status that looks something like the following:

    {
    "message": "Hello from k-app on Kubernetes",
    "version": "0.1.0",
    "hostname": "k-app-74c7d8dccf-nb2m4",
    "uptime_seconds": 133.5
    }


The intended way for you to run it, is to use the buttons on the VS Code status bar (bottom left of the window frame). 

[ ▶ Continuous Deploy, () Deploy Once, 🌐 Open App, ()DevSpace UI, 🗑 Remove ]

If you use "Continuous Deploy", and make changes to the app code, the app will auto-update itself very soon after you save the code file. Watch the Terminal output to keep an eye on the process of the newly deployed code. It should start displaying something in 5-10 seconds after you save the file.

(If you do not see the buttons, you need to install the "Task Buttons" extension for VSCode. The buttons and tasks live in `.vscode/`.
)

| Button | What it does |
|---|---|
| **Continuous Deploy** | Builds, deploys and syncs `app/` into the cluster, with the app on http://k-app.localhost (and http://localhost:8080). Saving a file in `app/` copies it into the running container and restarts the app. Edits to the `Dockerfile` or `devspace-k8s/` are not picked up until you stop and restart it. What runs is the first build plus synced files, not a fresh image, so check with **Deploy Once** before trusting a result. Stop with the trash icon on its terminal panel. |
| **Deploy Once** | One-off build and deploy, as CI would do. It does not do continuous sync. |
| **Open App** | Opens your browser to http://k-app.localhost. This will only work after you have used aeither deploy button. |
| **DevSpace UI** | Opens DevSpace's web page, which should give you access to: logs, a shell in the pod, ports. |
| **Remove** | Deletes k-app from the cluster. |

From a kubernetes perspective, everything gets installed under the `k-app` namespace. 

# Directory Layout
    `Dockerfile` (non-root image)
    `devspace-k8s/` (plain manifests CI would apply, including an Ingress on `k-app.localhost` via Rancher Desktop's Traefik),
    `devspace.yaml` (local dev loop only).
