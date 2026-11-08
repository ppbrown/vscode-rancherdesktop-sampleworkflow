# k-app

Purpose of this repo is to explore container development dev cycle
from the perspective of a windows desktop user.

This should simulate an app that is intended for eventual enterprise
deployment, using CI that is not present here, but inferred
as already existing

Local dev should take place using rancher-desktop+cluster that
is already installed and working

initial prototype should use devspace installed natively on windows
presumed already installed. (or use [install-devspace.ps1](install-devspace.ps1) )


## Test app

`app/main.py` is a tiny stdlib-only Python HTTP service (port 8080):
`/` returns a JSON greeting/version/hostname, `/healthz` and `/readyz` are probes.
Config via env: `GREETING`, `APP_VERSION`, `PORT`, `LOG_LEVEL`.

```powershell
devspace use namespace k-app   # once; or pass -n k-app
devspace dev                   # build, deploy, sync ./app, forward localhost:8080
                               # edits to app/ restart the container automatically
devspace deploy                # plain build + deploy (what CI would do)
devspace purge                 # remove it
```

Layout: `Dockerfile` (non-root image), `k8s/` (plain manifests CI would apply),
`devspace.yaml` (local dev loop only).
