#!/usr/bin/env bash
# Project management helper functions
# Source this from your dotfiles (~/.zshrc or ~/.bashrc):
#   source ~/github.com/ymd000/workspaece-structure/project/functions.sh

# ── Constants ─────────────────────────────────────────────────────────────────

_SANDBOX_DIR="${HOME}/sandbox"
_GIT_DIR="${HOME}/github.com/ymd000"

# ── new-project ───────────────────────────────────────────────────────────────
# Usage: new-project <name>
# Creates ~/sandbox/YYYY-MM-DD/<name>/ and cd into it.
new-project() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: new-project <name>" >&2
    return 1
  fi

  local date dir
  date="$(command date +%Y-%m-%d)"
  dir="${_SANDBOX_DIR}/${date}/${name}"

  if [[ -e "$dir" ]]; then
    echo "Already exists: $dir" >&2
    return 1
  fi

  mkdir -p "$dir"
  echo "Created: $dir"
  cd "$dir" || return 1
}

# ── promote-to-git ────────────────────────────────────────────────────────────
# Usage: promote-to-git
# Initializes a git repository in the current directory.
# Intended for use in sandbox projects before running git-promote-finish.
promote-to-git() {
  if [[ -d ".git" ]]; then
    echo "Already a git repository." >&2
    return 1
  fi

  git init
  git add -A

  echo ""
  echo "Git initialized. Next steps:"
  echo "  1. git commit -m \"Initial commit\""
  echo "  2. Create the repo on GitHub"
  echo "  3. git-promote-finish $(basename "$PWD")"
}

# ── git-promote-finish ────────────────────────────────────────────────────────
# Usage: git-promote-finish [name]
# Moves the current sandbox git project to ~/github.com/ymd000/<name>/
# and sets up the GitHub remote if provided.
# Defaults to the current directory name.
git-promote-finish() {
  local name="${1:-$(basename "$PWD")}"

  if [[ ! -d ".git" ]]; then
    echo "Error: not a git repository. Run 'promote-to-git' first." >&2
    return 1
  fi

  if [[ "$PWD" != "${_SANDBOX_DIR}/"* ]]; then
    echo "Warning: not in sandbox directory. Proceeding anyway."
  fi

  local src dest
  src="$PWD"
  dest="${_GIT_DIR}/${name}"

  if [[ -e "$dest" ]]; then
    echo "Error: destination already exists: $dest" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dest")"
  mv "$src" "$dest"
  echo "Moved: $src -> $dest"
  cd "$dest" || return 1

  echo ""
  echo "Next: add remote and push"
  echo "  git remote add origin git@github.com:ymd000/${name}.git"
  echo "  git push -u origin main"
}

# ── gclone ────────────────────────────────────────────────────────────────────
# Usage: gclone <url>
# Clones a git repository into the appropriate ~/github.com/user/repo structure.
# Supports https:// and git@host:user/repo.git formats.
gclone() {
  local url="$1"
  if [[ -z "$url" ]]; then
    echo "Usage: gclone <url>" >&2
    return 1
  fi

  local host user repo dest

  if [[ "$url" =~ ^https?://([^/]+)/([^/]+)/([^/]+?)(.git)?$ ]]; then
    host="${BASH_REMATCH[1]}"
    user="${BASH_REMATCH[2]}"
    repo="${BASH_REMATCH[3]}"
  elif [[ "$url" =~ ^git@([^:]+):([^/]+)/([^/]+?)(.git)?$ ]]; then
    host="${BASH_REMATCH[1]}"
    user="${BASH_REMATCH[2]}"
    repo="${BASH_REMATCH[3]}"
  else
    echo "Error: cannot parse URL: $url" >&2
    echo "Expected: https://github.com/user/repo or git@github.com:user/repo.git" >&2
    return 1
  fi

  dest="${HOME}/${host}/${user}/${repo}"

  if [[ -e "$dest" ]]; then
    echo "Already exists: $dest"
    cd "$dest" || return 1
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  git clone "$url" "$dest" || return 1
  echo "Cloned: $dest"
  cd "$dest" || return 1
}

# ── grepo ─────────────────────────────────────────────────────────────────────
# Usage: grepo <keyword>
# Searches for repositories under ~/github.com, ~/gitlab.com, ~/gist.github.com
# and cd into the matching one. Prompts if multiple matches.
grepo() {
  local keyword="$1"
  if [[ -z "$keyword" ]]; then
    echo "Usage: grepo <keyword>" >&2
    return 1
  fi

  local -a search_dirs=()
  [[ -d "${HOME}/github.com" ]]       && search_dirs+=("${HOME}/github.com")
  [[ -d "${HOME}/gitlab.com" ]]       && search_dirs+=("${HOME}/gitlab.com")
  [[ -d "${HOME}/gist.github.com" ]]  && search_dirs+=("${HOME}/gist.github.com")

  if [[ ${#search_dirs[@]} -eq 0 ]]; then
    echo "No git hosting directories found under \$HOME." >&2
    return 1
  fi

  local -a repos
  mapfile -t repos < <(
    find "${search_dirs[@]}" \
      -maxdepth 2 -mindepth 2 -type d \
      -name "*${keyword}*" 2>/dev/null | sort
  )

  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "No repositories matching: $keyword" >&2
    return 1
  fi

  if [[ ${#repos[@]} -eq 1 ]]; then
    echo "${repos[0]}"
    cd "${repos[0]}" || return 1
    return 0
  fi

  echo "Multiple repositories found:"
  local i
  for i in "${!repos[@]}"; do
    printf "  %d. %s\n" $((i + 1)) "${repos[$i]}"
  done
  read -r -p "Select [1-${#repos[@]}]: " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#repos[@]} )); then
    cd "${repos[$((choice - 1))]}" || return 1
  else
    echo "Invalid selection." >&2
    return 1
  fi
}

# ── clean-sandbox ─────────────────────────────────────────────────────────────
# Usage: clean-sandbox [days]
# Deletes date-named directories under ~/sandbox/ older than <days> (default: 30).
# Uses directory name (YYYY-MM-DD) to determine age, not mtime.
clean-sandbox() {
  local days="${1:-30}"

  if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo "Usage: clean-sandbox [days]" >&2
    return 1
  fi

  if [[ ! -d "$_SANDBOX_DIR" ]]; then
    echo "Sandbox directory not found: $_SANDBOX_DIR" >&2
    return 1
  fi

  local today_epoch
  today_epoch="$(command date +%s)"

  local -a old_dirs=()
  local entry dir_date dir_epoch age_days

  for entry in "${_SANDBOX_DIR}"/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]; do
    [[ -d "$entry" ]] || continue
    dir_date="$(basename "$entry")"
    dir_epoch="$(command date -d "$dir_date" +%s 2>/dev/null)" || continue
    age_days=$(( (today_epoch - dir_epoch) / 86400 ))
    (( age_days > days )) && old_dirs+=("$entry")
  done

  if [[ ${#old_dirs[@]} -eq 0 ]]; then
    echo "No directories older than ${days} days in ${_SANDBOX_DIR}."
    return 0
  fi

  echo "Directories to delete (older than ${days} days):"
  for d in "${old_dirs[@]}"; do
    echo "  $d"
  done

  read -r -p "Delete these directories? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for d in "${old_dirs[@]}"; do
      rm -rf "$d"
      echo "Deleted: $d"
    done
  else
    echo "Cancelled."
  fi
}
