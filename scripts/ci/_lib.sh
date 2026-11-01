# Shared helpers for scripts/ci/*.sh. Source, do not execute.
#
# Conventions:
#   - All scripts `set -euo pipefail`.
#   - All scripts `cd` to the repo root via `repo_root` before doing work.
#   - All scripts validate their env contract via `require_env` before running.

# Resolve the repo root from this file's location. Works regardless of the
# caller's cwd. Realpath via a portable shell idiom (no `realpath` binary).
_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${_lib_dir}/../.." && pwd)"

# Print a banner. Used to visually separate phases when running test-all-local.
banner() {
  printf '\n================================================\n'
  printf '%s\n' "$*"
  printf '================================================\n'
}

# Print to stderr.
log() {
  printf '%s\n' "$*" >&2
}

# Abort with a message.
die() {
  log "error: $*"
  exit 1
}

# Validate that each named env var is set and non-empty.
# Usage: require_env VAR1 VAR2 VAR3
require_env() {
  local missing=()
  local var
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("${var}")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    die "missing required env vars: ${missing[*]}"
  fi
}

# Require that a command is on PATH.
# Usage: require_cmd uv docker
require_cmd() {
  local missing=()
  local cmd
  for cmd in "$@"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      missing+=("${cmd}")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    die "missing required commands: ${missing[*]}"
  fi
}

# Set GITHUB_SHA if it's not already set. Used by integration_test_project
# profiles.yml to generate per-run schema names. CI sets this automatically;
# local runs need a value so dbt schemas don't collide.
ensure_github_sha() {
  if [[ -z "${GITHUB_SHA:-}" ]]; then
    if command -v git >/dev/null 2>&1 && git -C "${repo_root}" rev-parse HEAD >/dev/null 2>&1; then
      export GITHUB_SHA="local_$(git -C "${repo_root}" rev-parse --short HEAD)"
    else
      export GITHUB_SHA="local_$(date +%s)"
    fi
    log "GITHUB_SHA not set; using ${GITHUB_SHA}"
  fi
}
