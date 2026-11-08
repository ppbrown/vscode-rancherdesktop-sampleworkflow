#!/usr/bin/env bash
# Install Rancher Desktop on Linux and start it with the settings k-app expects:
#   - container engine: dockerd (moby), so the docker CLI works
#   - Kubernetes enabled
# Counterpart of install-rancher.ps1 for Windows. Uses sudo for system changes.
set -euo pipefail

repo="https://download.opensuse.org/repositories/isv:/Rancher:/stable"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }; }
need sudo
need curl

# --- Install the package (skipped if already installed) ------------------
user="${USER:-$(id -un)}"

# The "stable" repo also carries prereleases (e.g. 2.0.0alpha), which package
# managers rank above the latest release. Pick the newest real release instead.
# Reads one version per line on stdin.
newest_release() {
  local v
  v="$(grep -v '^$' | grep -viE 'alpha|beta|rc' | sort -V | tail -1)"
  if [ -z "$v" ]; then
    echo "Could not find a released rancher-desktop version in the repo." >&2
    exit 1
  fi
  echo "Selected rancher-desktop $v" >&2
  echo "$v"
}

if [ -x /opt/rancher-desktop/rancher-desktop ] || command -v rancher-desktop >/dev/null 2>&1; then
  echo "Rancher Desktop is already installed."
elif command -v apt-get >/dev/null 2>&1; then
  echo "Installing Rancher Desktop from the openSUSE Build Service apt repo..."
  need gpg
  keyring=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg
  curl -fsSL "$repo/deb/Release.key" | gpg --dearmor | sudo tee "$keyring" >/dev/null
  echo "deb [signed-by=$keyring] $repo/deb/ ./" \
    | sudo tee /etc/apt/sources.list.d/isv-rancher-stable.list >/dev/null
  sudo apt-get update
  ver="$(apt-cache madison rancher-desktop | awk -F'|' '{gsub(/ /, "", $2); print $2}' | newest_release)"
  sudo apt-get install -y "rancher-desktop=$ver"
elif command -v zypper >/dev/null 2>&1; then
  echo "Installing Rancher Desktop with zypper..."
  sudo zypper --non-interactive addrepo --refresh "$repo/rpm/isv:Rancher:stable.repo" || true
  sudo zypper --non-interactive --gpg-auto-import-keys refresh
  ver="$(sudo zypper --non-interactive search -s --match-exact rancher-desktop \
    | awk -F'|' '{ for (i = 1; i <= NF; i++) gsub(/^ +| +$/, "", $i) }
                 $2 == "rancher-desktop" && $3 == "package" { print $4 }' \
    | newest_release)"
  sudo zypper --non-interactive install "rancher-desktop=$ver"
elif command -v dnf >/dev/null 2>&1; then
  echo "Installing Rancher Desktop with dnf..."
  # Drop the .repo file in directly; works with both dnf4 and dnf5.
  sudo curl -fsSL "$repo/rpm/isv:Rancher:stable.repo" -o /etc/yum.repos.d/isv-rancher-stable.repo
  ver="$(dnf repoquery -q --qf '%{version}-%{release}\n' rancher-desktop | newest_release)"
  sudo dnf install -y "rancher-desktop-$ver"
else
  echo "No supported package manager found (apt-get, zypper, dnf)." >&2
  echo "Use the AppImage instead: https://docs.rancherdesktop.io/getting-started/installation/" >&2
  exit 1
fi

# --- KVM access: the VM won't start without it ---------------------------
if [ ! -e /dev/kvm ]; then
  echo "WARNING: /dev/kvm not found. Enable virtualisation (VT-x/AMD-V) in the BIOS." >&2
elif [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
  if getent group kvm >/dev/null; then
    echo "Adding $user to the kvm group (log out and back in for it to apply)..."
    sudo usermod -aG kvm "$user"
    relogin=1
  else
    echo "WARNING: no access to /dev/kvm and no 'kvm' group; check your distro's KVM docs." >&2
  fi
fi

# --- Let Traefik bind port 80, so http://k-app.localhost works -----------
# Read via /proc: sysctl may be in /usr/sbin, off a normal user's PATH.
if [ "$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start)" -gt 80 ]; then
  echo "Allowing unprivileged ports from 80 (for the Kubernetes ingress)..."
  echo 'net.ipv4.ip_unprivileged_port_start=80' \
    | sudo tee /etc/sysctl.d/99-rancher-desktop.conf >/dev/null
  sudo sysctl -q -w net.ipv4.ip_unprivileged_port_start=80
fi

# --- Start it (or update settings if already running) --------------------
rdctl=/opt/rancher-desktop/resources/resources/linux/bin/rdctl
if [ "${relogin:-0}" = 1 ]; then
  echo
  echo "Installed. Log out and back in (for kvm access), then start Rancher Desktop"
  echo "and choose dockerd (moby) with Kubernetes enabled, or run:"
  echo "    $rdctl start --container-engine.name=moby --kubernetes.enabled=true"
  exit 0
fi
if [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  echo "Installed. No desktop session detected; start Rancher Desktop from your desktop," >&2
  echo "choosing dockerd (moby) with Kubernetes enabled." >&2
  exit 0
fi

echo "Starting Rancher Desktop with dockerd (moby) and Kubernetes enabled..."
"$rdctl" start --container-engine.name=moby --kubernetes.enabled=true

echo
echo "Done. The first start downloads Kubernetes and can take a few minutes;"
echo "watch progress in the Rancher Desktop window. docker, kubectl and rdctl"
echo "land in ~/.rd/bin; Rancher Desktop offers to add that to your PATH."
