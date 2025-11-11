#!/bin/zsh
# === ms (merge safe) ===

source "$(dirname "$0")/_colors.zsh"

# === CONFIG ===
TARGET_BRANCH=""
FORCE_MODE=false
NO_EDIT_MODE=false
SILENT_MODE=false

# === ARG PARSER ===
for arg in "$@"; do
  case $arg in
    --force|-F)
      FORCE_MODE=true
      ;;
    --no-edit|-ne)
      NO_EDIT_MODE=true
      ;;
    --silent|-s)
      SILENT_MODE=true
      ;;
    *)
      if [ -z "$TARGET_BRANCH" ]; then
        TARGET_BRANCH="$arg"
      fi
      ;;
  esac
done

if [ -z "$TARGET_BRANCH" ]; then
  echo "${RED}❌ Please provide a target branch.${RESET}"
  echo "Usage: ${YELLOW}ms <target-branch> [--force|-F] [--no-edit|-ne] [--silent|-s]${RESET}"
  echo "Example: ${YELLOW}ms main -F -ne -s${RESET}"
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
  echo "${RED}❌ Not inside a Git repository.${RESET}"
  exit 1
fi

# === LOG FUNCTION ===
log() {
  if [ "$SILENT_MODE" = false ]; then
    echo "$@"
  fi
}

log "${CYAN}📦 Current branch:${RESET} $CURRENT_BRANCH"
log "${CYAN}🎯 Target branch:${RESET} $TARGET_BRANCH"

# === CONFIRMATION ===
if [ "$FORCE_MODE" = false ] && [ "$SILENT_MODE" = false ]; then
  echo -n "${YELLOW}Are you sure you want to merge '${CURRENT_BRANCH}' into '${TARGET_BRANCH}'? (y/N): ${RESET}"
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "${RED}❌ Merge canceled by user.${RESET}"
    exit 0
  fi
elif [ "$FORCE_MODE" = true ]; then
  log "${YELLOW}⚡ Force mode enabled. Skipping confirmation.${RESET}"
fi

# === STASH UNCOMMITTED CHANGES ===
if ! git diff --quiet || ! git diff --cached --quiet; then
  log "${YELLOW}💾 Stashing uncommitted changes...${RESET}"
  git stash push -u -m "auto-stash-before-merge-to-$TARGET_BRANCH"
  STASHED=true
fi

# === SWITCH TO TARGET BRANCH ===
log "${BLUE}🔄 Switching to ${TARGET_BRANCH}...${RESET}"
if ! git checkout "$TARGET_BRANCH" >/dev/null 2>&1; then
  echo "${RED}❌ Failed to checkout ${TARGET_BRANCH}.${RESET}"
  exit 1
fi

# === UPDATE TARGET BRANCH ===
log "${BLUE}⬇️  Updating ${TARGET_BRANCH}...${RESET}"
git fetch origin "$TARGET_BRANCH" >/dev/null 2>&1
if ! git pull --rebase >/dev/null 2>&1; then
  echo "${RED}❌ Pull failed. Aborting.${RESET}"
  git checkout "$CURRENT_BRANCH" >/dev/null 2>&1
  exit 1
fi

# === MERGE CURRENT BRANCH ===
log "${BLUE}🔀 Merging ${CURRENT_BRANCH} into ${TARGET_BRANCH}...${RESET}"

MERGE_CMD=(git merge --no-ff)
if [ "$NO_EDIT_MODE" = true ]; then
  MERGE_CMD+=(--no-edit)
  log "${YELLOW}✏️  Using --no-edit (skip merge message editor)...${RESET}"
fi

if "${MERGE_CMD[@]}" "$CURRENT_BRANCH" >/dev/null 2>&1; then
  log "${GREEN}✅ Merge successful. Pushing to origin...${RESET}"
  git push origin "$TARGET_BRANCH" >/dev/null 2>&1
  MERGE_SUCCESS=true
else
  echo "${YELLOW}⚠️ Merge conflict detected!${RESET}"
  echo "${RED}🧩 Aborting merge to prevent messy state.${RESET}"
  git merge --abort >/dev/null 2>&1
  MERGE_SUCCESS=false
fi

# === SWITCH BACK ===
log "${BLUE}↩️  Returning to ${CURRENT_BRANCH}...${RESET}"
git checkout "$CURRENT_BRANCH" >/dev/null 2>&1

# === RESTORE STASH IF EXISTS ===
if [ "$STASHED" = true ]; then
  log "${YELLOW}📂 Restoring stashed changes...${RESET}"
  git stash pop >/dev/null 2>&1 || echo "${YELLOW}⚠️ Failed to apply stashed changes.${RESET} Check manually with: ${CYAN}git stash list${RESET}"
fi

# === DONE ===
if [ "$MERGE_SUCCESS" = true ]; then
  log "${GREEN}🎉 Done! ${CURRENT_BRANCH} successfully merged into ${TARGET_BRANCH} and pushed.${RESET}"
else
  echo "${RED}❌ Merge aborted due to conflicts. Please resolve manually.${RESET}"
fi
