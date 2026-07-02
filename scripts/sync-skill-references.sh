#!/usr/bin/env bash
#
# Regenerate each skill's references/ directory from the canonical knowledge/
# and workflows/ directories.
#
# knowledge/ and workflows/ are the single source of truth. The copies under
# skills/<skill>/references/ exist only so each skill installs self-contained
# via `npx skills add` — they are GENERATED, not hand-edited. Edit the files in
# knowledge/ or workflows/, then run this script to propagate the change.
#
# Usage:  ./scripts/sync-skill-references.sh
#
set -euo pipefail
cd "$(dirname "$0")/.."

sync() { # sync <skill-name> <source-path>...
  local skill="$1"; shift
  local dest="skills/${skill}/references"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$@" "$dest"/
  echo "  synced skills/${skill}/references/ <- $*"
}

sync linkup-search \
  knowledge/LINKUP_AGENT_QUERY_MENTAL_MODEL.md \
  knowledge/LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md \
  knowledge/LINKUP_API_REFERENCE.md
sync linkup-fetch \
  knowledge/LINKUP_API_REFERENCE.md
sync linkup-research \
  knowledge/LINKUP_SPECIALIZED_ENDPOINTS.md
sync linkup-extract \
  knowledge/LINKUP_SPECIALIZED_ENDPOINTS.md
sync linkup-workflow \
  knowledge/LINKUP_WORKFLOW_GUIDE.md \
  knowledge/LINKUP_WORKFLOW_OPTIMIZER_KNOWLEDGE.md \
  workflows

echo "Done. skills/*/references/ regenerated from knowledge/ and workflows/."
