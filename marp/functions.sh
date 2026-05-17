#!/usr/bin/env bash
# Marp presentation helper functions
# Source this from your dotfiles (~/.zshrc or ~/.bashrc):
#   source ~/github.com/ymd000/workspaece-structure/marp/functions.sh
#
# Setup:
#   mkdir -p ~/.config/marp/themes
#   cp ~/github.com/ymd000/workspaece-structure/marp/themes/demo.css ~/.config/marp/themes/
#
# Marp CLI install:
#   npm install -g @marp-team/marp-cli

# ── Constants ─────────────────────────────────────────────────────────────────

_MARP_PRES_DIR="${HOME}/Documents/presentations"
_MARP_THEME_DIR="${HOME}/.config/marp/themes"
_MARP_THEME="demo"
_MARP_TEMPLATE="${HOME}/github.com/ymd000/workspaece-structure/marp/template.md"

# ── new-marp ───────────────────────────────────────────────────────────────────
# Usage: new-marp <title>
# Creates ~/Documents/presentations/YYYY/MM/YYYY-MM-DD-<title>.md
# and a symlink in the current directory if outside the presentations tree.
new-marp() {
  local title="$1"
  if [[ -z "$title" ]]; then
    echo "Usage: new-marp <title>" >&2
    return 1
  fi

  local date year month filename dest_dir dest

  date="$(command date +%Y-%m-%d)"
  year="$(command date +%Y)"
  month="$(command date +%m)"
  filename="${date}-${title}.md"
  dest_dir="${_MARP_PRES_DIR}/${year}/${month}"
  dest="${dest_dir}/${filename}"

  mkdir -p "$dest_dir"

  if [[ -e "$dest" ]]; then
    echo "Already exists: $dest" >&2
    return 1
  fi

  # Populate from template, substituting title placeholder
  if [[ -f "$_MARP_TEMPLATE" ]]; then
    sed "s/プレゼンテーションタイトル/${title}/" "$_MARP_TEMPLATE" > "$dest"
  else
    cat > "$dest" << EOF
---
marp: true
theme: ${_MARP_THEME}
paginate: true
lang: ja
---

<!-- _class: title -->

# ${title}

## サブタイトル

発表者名

---

# スライドタイトル

内容

EOF
  fi

  # Symlink from current directory when outside the presentations tree
  if [[ "$PWD" != "${_MARP_PRES_DIR}"* ]]; then
    ln -sf "$dest" "./${filename}"
    echo "Created : $dest"
    echo "Symlink : ./${filename}"

    # images/ symlink: Marp resolves image paths from the real file location,
    # so create presentations/YYYY/MM/images/ -> project/images/ to keep
    # image references as ![](images/foo.png) in both preview and export.
    mkdir -p "$PWD/images"
    local img_link="${dest_dir}/images"
    if [[ -L "$img_link" ]]; then
      echo "Note    : images symlink already exists: $img_link"
    elif [[ -e "$img_link" ]]; then
      echo "Note    : images/ already exists as a real dir: $img_link"
    else
      ln -sf "$PWD/images" "$img_link"
      echo "Images  : ./images/ -> $img_link"
    fi
  else
    echo "Created : $dest"
  fi

  "${EDITOR:-nvim}" "$dest"
}

# ── list-marp ─────────────────────────────────────────────────────────────────
# Usage: list-marp [year [month]]
list-marp() {
  local year="${1:-}"
  local month="${2:-}"
  local search_dir="${_MARP_PRES_DIR}"

  if [[ -n "$year" && -n "$month" ]]; then
    search_dir="${_MARP_PRES_DIR}/${year}/${month}"
  elif [[ -n "$year" ]]; then
    search_dir="${_MARP_PRES_DIR}/${year}"
  fi

  if [[ ! -d "$search_dir" ]]; then
    echo "No presentations found in: $search_dir" >&2
    return 1
  fi

  find "$search_dir" -name "*.md" | sort
}

# ── edit-marp ─────────────────────────────────────────────────────────────────
# Usage: edit-marp <keyword>
edit-marp() {
  local keyword="$1"
  if [[ -z "$keyword" ]]; then
    echo "Usage: edit-marp <keyword>" >&2
    return 1
  fi

  local -a files
  mapfile -t files < <(find "${_MARP_PRES_DIR}" -name "*${keyword}*.md" | sort)

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No presentations matching: $keyword" >&2
    return 1
  fi

  if [[ ${#files[@]} -eq 1 ]]; then
    "${EDITOR:-nvim}" "${files[0]}"
    return
  fi

  echo "Multiple presentations found:"
  local i
  for i in "${!files[@]}"; do
    printf "  %d. %s\n" $((i + 1)) "${files[$i]}"
  done
  read -r -p "Select [1-${#files[@]}]: " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#files[@]} )); then
    "${EDITOR:-nvim}" "${files[$((choice - 1))]}"
  else
    echo "Invalid selection" >&2
    return 1
  fi
}

# ── _marp_chrome_path ─────────────────────────────────────────────────────────
# Resolve Chrome/Chromium path; echo empty string if not found.
_marp_chrome_path() {
  # Explicit override wins
  [[ -n "$CHROME_PATH" ]] && { echo "$CHROME_PATH"; return; }

  local candidates=(
    /usr/bin/google-chrome
    /usr/bin/google-chrome-stable
    /usr/bin/chromium
    /usr/bin/chromium-browser
    /snap/bin/chromium
    /opt/google/chrome/google-chrome
  )
  local c
  for c in "${candidates[@]}"; do
    [[ -x "$c" ]] && { echo "$c"; return; }
  done
}

# ── export-marp ───────────────────────────────────────────────────────────────
# Usage: export-marp <file.md> [pdf|pptx|html]  (default: pdf)
# PDF/PPTX require Chrome or Chromium. Install: sudo snap install chromium
export-marp() {
  local input="$1"
  local format="${2:-pdf}"

  if [[ -z "$input" ]]; then
    echo "Usage: export-marp <file.md> [pdf|pptx|html]" >&2
    return 1
  fi

  if ! command -v marp &> /dev/null; then
    echo "marp not found. Install: npm install -g @marp-team/marp-cli" >&2
    return 1
  fi

  local theme_opt=()
  if [[ -d "$_MARP_THEME_DIR" ]]; then
    theme_opt=(--theme-set "$_MARP_THEME_DIR")
  fi

  # PDF/PPTX need a Chrome-based browser; HTML does not
  if [[ "$format" != "html" ]]; then
    local chrome
    chrome="$(_marp_chrome_path)"
    if [[ -z "$chrome" ]]; then
      echo "ERROR: Chrome/Chromium not found. Install with:" >&2
      echo "  sudo snap install chromium" >&2
      echo "Or set CHROME_PATH=/path/to/chrome and retry." >&2
      return 1
    fi
    CHROME_PATH="$chrome" marp "${theme_opt[@]}" --allow-local-files "--${format}" "$input"
  else
    marp "${theme_opt[@]}" "--${format}" "$input"
  fi

  echo "Exported: ${input%.*}.${format}"
}

# ── export-marp-editable ──────────────────────────────────────────────────────
# Usage: export-marp-editable <file.md>
# Exports to editable PPTX via pandoc — text/shapes are native PPTX elements,
# not images, so they can be edited in LibreOffice/PowerPoint.
# Uses demo.pptx as reference template (colors, fonts, layouts are inherited).
# Marp-specific directives (_class, _footer) are silently ignored.
export-marp-editable() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "Usage: export-marp-editable <file.md>" >&2
    return 1
  fi

  if ! command -v pandoc &> /dev/null; then
    echo "pandoc not found. Install: sudo apt install pandoc" >&2
    return 1
  fi

  local output="${input%.*}.pptx"
  local reference="${HOME}/github.com/ymd000/workspaece-structure/marp/pandoc-reference.pptx"

  local ref_opt=()
  [[ -f "$reference" ]] && ref_opt=(--reference-doc="$reference")

  pandoc "$input" \
    --from markdown \
    --to pptx \
    --slide-level=1 \
    "${ref_opt[@]}" \
    -o "$output"

  echo "Exported (editable): $output"
}

# ── marp-preview ──────────────────────────────────────────────────────────────
# Usage: marp-preview <file.md> [port]
# Starts an HTTP server for live preview. Open http://localhost:<port> in a browser.
# Uses --server instead of --preview to avoid requiring a local browser binary.
marp-preview() {
  local input="$1"
  local port="${2:-8080}"

  if [[ -z "$input" ]]; then
    echo "Usage: marp-preview <file.md> [port]" >&2
    return 1
  fi

  if ! command -v marp &> /dev/null; then
    echo "marp not found. Install: npm install -g @marp-team/marp-cli" >&2
    return 1
  fi

  local theme_opt=()
  if [[ -d "$_MARP_THEME_DIR" ]]; then
    theme_opt=(--theme-set "$_MARP_THEME_DIR")
  fi

  echo "Preview: http://localhost:${port}"
  echo "Press Ctrl-C to stop."
  marp "${theme_opt[@]}" --server --port "$port" "$(dirname "$input")"
}
