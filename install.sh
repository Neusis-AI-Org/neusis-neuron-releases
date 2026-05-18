#!/usr/bin/env bash
# neusis-neuron-mcp installer for Linux and macOS.
#
# Usage:
#   curl -fsSL https://neusis-ai-org.github.io/neusis-neuron-releases/install.sh | bash
#
# Environment variables:
#   VERSION      Pin a specific release version (default: latest).
#   INSTALL_DIR  Install location (default: $HOME/.local/bin).
#
# Re-running this script upgrades an existing install in place.

set -euo pipefail

REPO="Neusis-AI-Org/neusis-neuron-releases"
BINARY="neusis-neuron-mcp"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

case "$(uname -s)" in
  Linux*)  OS="Linux"  ;;
  Darwin*) OS="Darwin" ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  ARCH="x86_64" ;;
  aarch64|arm64) ARCH="arm64"  ;;
  *) echo "Unsupported arch: $(uname -m). Builds target amd64/arm64 only." >&2; exit 1 ;;
esac

if [ -z "${VERSION:-}" ]; then
  VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -m1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
  if [ -z "$VERSION" ]; then
    echo "Could not resolve the latest release version." >&2
    exit 1
  fi
fi
VERSION="${VERSION#v}"

ARCHIVE="${BINARY}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/$REPO/releases/download/v${VERSION}/${ARCHIVE}"

echo "Downloading $BINARY v$VERSION ($OS/$ARCH)..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$URL" -o "$TMPDIR/$ARCHIVE"
tar -xzf "$TMPDIR/$ARCHIVE" -C "$TMPDIR"

mkdir -p "$INSTALL_DIR"
# install overwrites in place, so reruns upgrade an existing binary.
install -m 755 "$TMPDIR/$BINARY" "$INSTALL_DIR/$BINARY"
echo "Installed: $INSTALL_DIR/$BINARY"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo
    echo "Warning: $INSTALL_DIR is not on your PATH."
    echo "Add this to your shell profile (.bashrc / .zshrc):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac

echo
echo "Next steps -----------------------------------------------------"
echo "1. Create a fine-grained GitHub token with Contents: Read on your"
echo "   KB repository:"
echo "   https://github.com/settings/personal-access-tokens/new"
echo
echo "2. Register the server in neusis-code's neusiscode.json:"
echo
cat <<'JSON'
   {
     "mcp": {
       "neusis-neuron": {
         "type": "local",
         "command": ["neusis-neuron-mcp", "stdio", "--kb-repo", "OWNER/REPO"],
         "environment": { "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token" },
         "enabled": true
       }
     }
   }
JSON
