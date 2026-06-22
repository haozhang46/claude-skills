#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT

echo "Installing third-party skills..."

git clone --depth 1 --filter=blob:none --sparse https://github.com/vercel-labs/agent-skills.git "$TMP/agent-skills"
cd "$TMP/agent-skills"
git sparse-checkout set skills/react-best-practices
cp -r skills/react-best-practices "$SCRIPT_DIR/vercel-react-best-practices"

echo "Done. Installed: vercel-react-best-practices"
