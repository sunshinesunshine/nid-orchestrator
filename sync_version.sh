#!/usr/bin/env bash
# ==============================================================================
# Nid Orchestrator Auto-Update & Versioning Script
# Synchronizes live AI Sandbox rules and diagram to GitHub repository
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

SOURCE_AGENTS="${WORKSPACE_ROOT}/AGENTS.md"
TARGET_AGENTS="${SCRIPT_DIR}/AGENTS.md"
SOURCE_DIAGRAM="${WORKSPACE_ROOT}/.gemini/antigravity/brain/bbc29a3e-c2a5-4a85-8338-0e14598083eb/nid_master_workflow.html"
TARGET_INDEX="${SCRIPT_DIR}/index.html"
VERSION_FILE="${SCRIPT_DIR}/VERSION"
CHANGELOG_FILE="${SCRIPT_DIR}/CHANGELOG.md"

BUMP_TYPE="${1:-patch}"
CUSTOM_MSG="${2:-}"

cd "${SCRIPT_DIR}"

# 1. Sync files from workspace root
if [[ -f "${SOURCE_AGENTS}" ]]; then
  cp "${SOURCE_AGENTS}" "${TARGET_AGENTS}"
fi

if [[ -f "${SOURCE_DIAGRAM}" ]]; then
  cp "${SOURCE_DIAGRAM}" "${TARGET_INDEX}"
fi

# 2. Check git status
CHANGES=$(git status --porcelain || true)
if [[ -z "${CHANGES}" ]]; then
  echo "✅ No changes detected in nid-orchestrator. Already up to date."
  exit 0
fi

# 3. Read current version and calculate next version
CURRENT_VERSION=$(cat "${VERSION_FILE}" | tr -d '[:space:]')
IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION}"

if [[ "${BUMP_TYPE}" == "major" ]]; then
  MAJOR=$((MAJOR + 1))
  MINOR=0
  PATCH=0
elif [[ "${BUMP_TYPE}" == "minor" ]]; then
  MINOR=$((MINOR + 1))
  PATCH=0
else
  PATCH=$((PATCH + 1))
fi

NEXT_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "${NEXT_VERSION}" > "${VERSION_FILE}"

# 4. Update CHANGELOG.md
TODAY=$(date "+%Y-%m-%d")
COMMIT_DESC="${CUSTOM_MSG:-Auto-update Nid Orchestrator specifications and diagram}"

TEMP_CHANGELOG=$(mktemp)
cat <<EOF > "${TEMP_CHANGELOG}"
# Changelog

All notable changes to **Nid (นิด / @nid) Orchestrator** will be documented in this file.

## [${NEXT_VERSION}] - ${TODAY}
- ${COMMIT_DESC}

EOF

tail -n +4 "${CHANGELOG_FILE}" >> "${TEMP_CHANGELOG}"
mv "${TEMP_CHANGELOG}" "${CHANGELOG_FILE}"

# 5. Git Commit & Push
git add -A
git commit -m "release: v${NEXT_VERSION} - ${COMMIT_DESC}"
git push origin main

echo "🚀 Successfully updated and pushed Nid Orchestrator v${NEXT_VERSION} to GitHub!"
echo "🌐 GitHub Pages will deploy automatically at: https://sunshinesunshine.github.io/nid-orchestrator/"
