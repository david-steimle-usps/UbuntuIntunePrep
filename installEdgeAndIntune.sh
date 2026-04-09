#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

log() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

run() {
  # run <cmd...>   (prints command; executes unless --dry-run)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] $*"
  else
    log "+ $*"
    "$@"
  fi
}

# Create a single backup dir for this run
BACKUP_DIR="/var/backups/UbuntuIntunePrep-$(date +%Y%m%d%H%M%S)"
ensure_backup_dir() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] mkdir -p ${BACKUP_DIR}"
  else
    mkdir -p "${BACKUP_DIR}"
  fi
}

backup_then_remove() {
  # backup_then_remove <file>
  local f="$1"
  ensure_backup_dir
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] cp -a -- \"$f\" \"${BACKUP_DIR}/\""
    log "[dry-run] rm -f -- \"$f\""
  else
    cp -a -- "$f" "${BACKUP_DIR}/"
    rm -f -- "$f"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  sudo ./installEdgeAndIntune.sh [--dry-run]

Options:
  --dry-run   Print actions without making changes.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage
  die "Too many arguments."
fi

# ---- Preconditions / basics ----
if [[ $EUID -ne 0 ]]; then
  die "Please run as root (e.g., sudo ./installEdgeAndIntune.sh)"
fi

ARCH="$(dpkg --print-architecture)"
if [[ "${ARCH}" != "amd64" ]]; then
  die "Unsupported architecture: ${ARCH}. This script supports amd64 only."
fi

# ---- Detect drive encryption (report-only) ----
log "Checking for drive encryption (report-only)..."
ROOT_SRC="$(findmnt -n -o SOURCE / || true)"
if [[ "${ROOT_SRC}" == /dev/mapper/* ]]; then
  if command -v cryptsetup >/dev/null 2>&1; then
    if cryptsetup status "${ROOT_SRC#/dev/}" >/dev/null 2>&1; then
      log "Encryption detected: root filesystem appears to be on a dm-crypt (likely LUKS) device (${ROOT_SRC})."
    else
      log "Possible encryption: root is on ${ROOT_SRC}, but unable to confirm via cryptsetup."
    fi
  else
    log "Possible encryption: root is on ${ROOT_SRC}. (Install 'cryptsetup' if you want stronger detection.)"
  fi
else
  if lsblk -f 2>/dev/null | grep -q 'crypto_LUKS'; then
    log "Encryption detected: at least one block device is LUKS-encrypted (crypto_LUKS)."
  else
    log "No LUKS encryption detected by basic heuristics."
  fi
fi

# ---- Install prerequisites ----
log "Installing prerequisites (ca-certificates, curl, gpg)..."
run apt-get update
run apt-get install -y --no-install-recommends ca-certificates curl gpg

# ---- Remediation: backup+remove ONLY sources that reference packages.microsoft.com ----
log "Scanning for existing Microsoft APT source entries (packages.microsoft.com)..."
shopt -s nullglob
MICROSOFT_SOURCE_FILES=()
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
  [[ -f "$f" ]] || continue
  if grep -qE 'packages\.microsoft\.com' "$f"; then
    MICROSOFT_SOURCE_FILES+=("$f")
  fi
done
shopt -u nullglob

if [[ "${#MICROSOFT_SOURCE_FILES[@]}" -eq 0 ]]; then
  log "No existing packages.microsoft.com sources found."
else
  log "Found ${#MICROSOFT_SOURCE_FILES[@]} Microsoft-related APT source file(s)."
  log "Backup directory for this run: ${BACKUP_DIR}"
  for f in "${MICROSOFT_SOURCE_FILES[@]}"; do
    log "  Backing up + removing: $f"
    backup_then_remove "$f"
  done
fi

# ---- Remove only the keyring this script manages ----
KEYRING="/usr/share/keyrings/microsoft-prod.gpg"
if [[ -f "${KEYRING}" ]]; then
  log "Removing existing keyring managed by this script: ${KEYRING}"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] rm -f -- ${KEYRING}"
  else
    rm -f -- "${KEYRING}"
  fi
fi

# ---- Add Microsoft signing key (single keyring) ----
log "Installing Microsoft signing key..."
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "[dry-run] curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee ${KEYRING} >/dev/null"
  log "[dry-run] chmod 0644 ${KEYRING}"
else
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | tee "${KEYRING}" >/dev/null
  chmod 0644 "${KEYRING}"
fi

# ---- Add repos (deb822 .sources) ----
log "Adding Microsoft prod repo (Ubuntu 24.04 / noble)..."
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "[dry-run] write /etc/apt/sources.list.d/microsoft-prod.sources"
else
  cat >/etc/apt/sources.list.d/microsoft-prod.sources <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/ubuntu/24.04/prod/
Suites: noble
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft-prod.gpg
EOF
fi

log "Adding Microsoft Edge repo..."
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "[dry-run] write /etc/apt/sources.list.d/microsoft-edge.sources"
else
  cat >/etc/apt/sources.list.d/microsoft-edge.sources <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/edge
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft-prod.gpg
EOF
fi

# ---- Update + install ----
log "Updating APT..."
run apt-get update

log "Installing Microsoft Edge + Intune Portal..."
run apt-get install -y microsoft-edge-stable intune-portal

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry-run complete. No changes were made."
else
  log "Done."
  if [[ -d "${BACKUP_DIR}" ]]; then
    log "Backups (if any files were removed) are in: ${BACKUP_DIR}"
  fi
fi
