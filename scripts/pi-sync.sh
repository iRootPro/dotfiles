#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/pi/agent"
DEST="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/pi-sync.sh [--dry-run] <backup|restore|status>

Synchronize non-secret Pi coding agent config between this dotfiles repo and
~/.pi/agent. This script never copies auth.json, sessions, OAuth credentials,
or other secret-bearing runtime state.
EOF
}

rsync_safe() {
  local args=(-a --delete)
  if [ "$DRY_RUN" = "1" ]; then
    args+=(-n -i)
  fi

  rsync "${args[@]}" \
    --exclude '__pycache__/' \
    --exclude '*.pyc' \
    --exclude '.env' \
    --exclude '.env.*' \
    --exclude '*.pem' \
    --exclude '*.key' \
    --exclude '*token*' \
    --exclude '*Token*' \
    --exclude '*credentials*' \
    --exclude '*Credentials*' \
    --exclude 'client_secret*.json' \
    --exclude 'client_secrets*.json' \
    --exclude 'auth.json' \
    --exclude 'sessions/' \
    --exclude 'npm/' \
    --exclude 'git/' \
    --exclude 'run-history.jsonl' \
    "$@"
}

secret_scan() {
  local found
  found="$(find "$SRC" -type f \( \
    -name '.env' -o -name '.env.*' -o \
    -iname '*token*' -o -iname '*credentials*' -o \
    -iname 'client_secret*.json' -o -iname 'client_secrets*.json' -o \
    -name '*.pem' -o -name '*.key' \
  \) -print 2>/dev/null || true)"

  if [ -n "$found" ]; then
    echo "Refusing: possible secret files found in repo Pi config:" >&2
    printf '%s\n' "$found" >&2
    return 1
  fi
}

status() {
  echo "Repo Pi config: $SRC"
  echo "Live Pi config: $DEST"
  echo ""
  echo "Tracked files:"
  find "$SRC" -type f | sed "s#^$ROOT/##" | sort || true
  echo ""
  if [ -d "$DEST/sessions" ]; then
    du -sh "$DEST/sessions" 2>/dev/null | sed 's/^/Live sessions: /'
  fi
}

backup() {
  if [ "$DRY_RUN" = "0" ]; then
    mkdir -p "$SRC/extensions" "$SRC/skills"
  fi

  if [ -d "$DEST/extensions" ]; then
    rsync_safe "$DEST/extensions/" "$SRC/extensions/"
  fi

  if [ -d "$DEST/skills" ]; then
    rsync_safe "$DEST/skills/" "$SRC/skills/"
  fi

  if [ "$DRY_RUN" = "0" ]; then
    secret_scan
  fi

  echo "Backed up non-secret Pi extensions/skills into $SRC"
  echo "Review the git diff before committing. Secrets and sessions were not copied."
}

restore() {
  if [ "$DRY_RUN" = "0" ]; then
    mkdir -p "$DEST/extensions" "$DEST/skills"
  fi

  if [ -d "$SRC/extensions" ]; then
    rsync_safe "$SRC/extensions/" "$DEST/extensions/"
  fi

  if [ -d "$SRC/skills" ]; then
    rsync_safe "$SRC/skills/" "$DEST/skills/"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "Dry run: left $DEST/settings.json unchanged."
  elif [ ! -f "$DEST/settings.json" ] && [ -f "$SRC/settings.template.json" ]; then
    cp "$SRC/settings.template.json" "$DEST/settings.json"
    chmod 600 "$DEST/settings.json" 2>/dev/null || true
    echo "Created $DEST/settings.json from template."
  else
    echo "Left existing $DEST/settings.json unchanged."
  fi

  echo "Restored non-secret Pi extensions/skills into $DEST"
  echo "Run: pi list"
}

cmd=""
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=1 ;;
    status|backup|restore) cmd="$arg" ;;
    -h|--help|help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

case "$cmd" in
  status) status ;;
  backup) backup ;;
  restore) restore ;;
  *) usage; exit 2 ;;
esac
