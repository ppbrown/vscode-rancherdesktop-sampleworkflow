#!/usr/bin/env bash
# Install the latest DevSpace CLI into ~/.local/bin (Linux; macOS works too).
# Counterpart of install-devspace.ps1 for Windows.
set -euo pipefail

dir="$HOME/.local/bin"

case "$(uname -s)" in
  Linux)  os=linux ;;
  Darwin) os=darwin ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

url="https://github.com/loft-sh/devspace/releases/latest/download/devspace-${os}-${arch}"

# Ensure directory exists
if [ ! -d "$dir" ]; then
  mkdir -p "$dir"
  echo "Created $dir"
fi

# Ensure it's on PATH for future shells
case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    line='export PATH="$HOME/.local/bin:$PATH"'
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      # Always update .bashrc; update .zshrc only if the user has one.
      if [ "$rc" = "$HOME/.bashrc" ] || [ -f "$rc" ]; then
        if ! grep -qsF "$line" "$rc"; then
          printf '\n# Added by install-devspace.sh\n%s\n' "$line" >> "$rc"
          echo "Added $dir to PATH in $rc (open a new terminal to pick it up)"
        fi
      fi
    done
    # Make it available for the rest of this script
    export PATH="$dir:$PATH"
    ;;
esac

# Download the binary
dest="$dir/devspace"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$tmp"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$url"
else
  echo "Need curl or wget to download DevSpace" >&2
  exit 1
fi
chmod +x "$tmp"
mv "$tmp" "$dest"
echo "Installed $dest"

"$dest" --version
