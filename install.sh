#!/bin/bash
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT

echo "Installing third-party skills..."

# vercel-labs/agent-skills
git clone --depth 1 --filter=blob:none --sparse https://github.com/vercel-labs/agent-skills.git "$TMP/agent-skills"
cd "$TMP/agent-skills"
git sparse-checkout set skills/react-best-practices skills/web-design-guidelines
cp -r skills/react-best-practices "$SCRIPT_DIR/vercel-react-best-practices"
cp -r skills/web-design-guidelines "$SCRIPT_DIR/web-design-guidelines"

# planning-with-files
git clone --depth 1 https://github.com/OthmanAdi/planning-with-files.git "$TMP/planning"
mkdir -p "$SCRIPT_DIR/planning-with-files"
cp "$TMP/planning/skills/planning-with-files/SKILL.md" "$SCRIPT_DIR/planning-with-files/"

echo ""
echo "Done. Installed:"
echo "  vercel-react-best-practices"
echo "  web-design-guidelines"
echo "  planning-with-files"
echo ""
echo "Superpowers — install manually via Claude Code plugin marketplace:"
echo "  claude plugin add anthropic/superpowers"
