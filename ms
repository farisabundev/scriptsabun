#!/bin/zsh
# === ms (merge safe) ===

source "$(dirname "$0")/_colors.zsh"

# === CONFIG ===
TARGET_BRANCH=$1

if [ -z "$TARGET_BRANCH" ]; then
  echo "${RED}❌ Please provide a target branch.${RESET}"
  echo "Usage: ${YELLOW}ms <target-branch>${RESET}"
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
  echo "${RED}❌ Not inside a Git repository.${RESET}"
  exit 1
fi

echo "${CYAN}📦 Current branch:${RESET} $CURRENT_BRANCH"
echo "${CYAN}🎯 Target branch:${RESET} $TARGET_BRANCH"

# === STASH UNCOMMITTED CHANGES (if any) ===
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "${YELLOW}💾 Stashing uncommitted changes...${RESET}"
  git stash push -u -m "auto-stash-before-merge-to-$TARGET_BRANCH"
  STASHED=true
fi

# === SWITCH TO TARGET BRANCH ===
echo "${BLUE}🔄 Switching to ${TARGET_BRANCH}...${RESET}"
if ! git checkout "$TARGET_BRANCH"; then
  echo "${RED}❌ Failed to checkout ${TARGET_BRANCH}.${RESET}"
  exit 1
fi

# === UPDATE TARGET BRANCH ===
echo "${BLUE}⬇️  Updating ${TARGET_BRANCH}...${RESET}"
git fetch origin "$TARGET_BRANCH"
if ! git pull --rebase; then
  echo "${RED}❌ Pull failed. Aborting.${RESET}"
  git checkout "$CURRENT_BRANCH"
  exit 1
fi

# === MERGE CURRENT BRANCH ===
echo "${BLUE}🔀 Merging ${CURRENT_BRANCH} into ${TARGET_BRANCH}...${RESET}"
if git merge --no-ff "$CURRENT_BRANCH"; then
  echo "${GREEN}✅ Merge successful. Pushing to origin...${RESET}"
  git push origin "$TARGET_BRANCH"
  MERGE_SUCCESS=true
else
  echo "${YELLOW}⚠️ Merge conflict detected!${RESET}"
  echo "${RED}🧩 Aborting merge to prevent messy state.${RESET}"
  git merge --abort
  MERGE_SUCCESS=false
fi

# === SWITCH BACK ===
echo "${BLUE}↩️  Returning to ${CURRENT_BRANCH}...${RESET}"
git checkout "$CURRENT_BRANCH"

# === RESTORE STASH IF EXISTS ===
if [ "$STASHED" = true ]; then
  echo "${YELLOW}📂 Restoring stashed changes...${RESET}"
  git stash pop || echo "${YELLOW}⚠️ Failed to apply stashed changes.${RESET} Check manually with: ${CYAN}git stash list${RESET}"
fi

# === DONE ===
if [ "$MERGE_SUCCESS" = true ]; then
  echo "${GREEN}🎉 Done! ${CURRENT_BRANCH} successfully merged into ${TARGET_BRANCH} and pushed.${RESET}"
else
  echo "${RED}❌ Merge aborted due to conflicts. Please resolve manually.${RESET}"
fi
