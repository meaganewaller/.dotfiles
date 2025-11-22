#!/usr/bin/env bash
set -eou pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/meaganewaller/.dotfiles.git}"

if [ -n "${DOTFILES_TARGET_DIR:-}" ]; then
    TARGET_DIR="${DOTFILES_TARGET_DIR}"
else
    # 3. Derive owner + repo name from the URL
    # Handles:
    #   https://github.com/owner/repo.git
    #   git@github.com:owner/repo.git
    #   ssh://git@github.com/owner/repo.git
    URL_NO_SCHEME="${REPO_URL#*@}"        # drop leading 'git@' if present
    URL_NO_SCHEME="${URL_NO_SCHEME#*://}" # drop scheme if present
    URL_PATH="${URL_NO_SCHEME#*:}"        # drop host + ':' in ssh form
    URL_PATH="${URL_PATH#*/}"             # drop host/ in https form (first segment is host)

    OWNER="${URL_PATH%%/*}"              # first segment = owner
    REPO_WITH_GIT="${URL_PATH#*/}"       # second segment = repo(.git)
    REPO="${REPO_WITH_GIT%.git}"         # strip .git if present

  # 4. Choose target dir based on whether ~/github exists
  if [ -d "${HOME}/github" ]; then
      # GitHub-style layout: ~/github/<owner>/<repo>
      TARGET_DIR="${HOME}/github/${OWNER}/${REPO}"
  else
      # Simple layout: ~/.dotfiles
      TARGET_DIR="${HOME}/.dotfiles"
  fi
fi

echo "[dotfiles] Repository URL: ${REPO_URL}"
echo "[dotfiles] Target directory: ${TARGET_DIR}"

# 5. Ensure parent directory exists
PARENT_DIR="$(dirname "$TARGET_DIR")"
mkdir -p "$PARENT_DIR"

# 6. Clone or update
if [ -d "$TARGET_DIR/.git" ]; then
  echo "[dotfiles] Repo already exists, pulling latest..."
  git -C "$TARGET_DIR" pull --ff-only
else
  echo "[dotfiles] Cloning into $TARGET_DIR..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"

# 7. Allow profile selection (with sensible default)
PROFILE="${DOTFILES_PROFILE:-work}"

echo "[dotfiles] Using profile: ${PROFILE}"

# 8. Hand off to installer
exec "$TARGET_DIR/install.sh" --profile "$PROFILE"
