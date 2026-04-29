#!/usr/bin/env bash
# AG Unity Skills autosetup.
# Builds and links the local ag-unity CLI command.
#
# Usage:
#   ./setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}  +${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*"; }
step() { echo -e "\n${CYAN}-- $* --${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_prereqs() {
  step "Checking prerequisites"

  if ! command -v node >/dev/null 2>&1; then
    err "Node.js not found. Install Node.js 18+ first."
    exit 1
  fi

  local node_major
  node_major="$(node -v | sed 's/v//' | cut -d. -f1)"
  if (( node_major < 18 )); then
    err "Node.js 18+ required. Found $(node -v)."
    exit 1
  fi
  ok "Node $(node -v)"

  if ! command -v npm >/dev/null 2>&1; then
    err "npm not found. It should be installed with Node.js."
    exit 1
  fi
  ok "npm $(npm -v)"
}

build_and_link_cli() {
  step "Building and linking ag-unity CLI"

  cd "$SCRIPT_DIR"
  info "Installing dependencies"
  npm install

  info "Building dist/cli/index.js"
  npm run build

  info "Linking ag-unity command"
  npm link

  ok "ag-unity linked"
}

verify_cli() {
  step "Verifying CLI command"

  if ! command -v ag-unity >/dev/null 2>&1; then
    err "ag-unity command was not found on PATH after npm link."
    exit 1
  fi

  local version
  version="$(ag-unity version)"
  ok "ag-unity version $version"
}

main() {
  echo ""
  echo "AG Unity Skills Autosetup"
  echo "========================="
  echo ""

  check_prereqs
  build_and_link_cli
  verify_cli

  echo ""
  echo "Setup complete."
  echo ""
  echo "Next:"
  echo "  cd /path/to/your/unity-project"
  echo "  ag-unity init"
  echo ""
}

case "${1:-}" in
  "" )
    main
    ;;
  --help|-h )
    echo "Usage: ./setup.sh"
    echo ""
    echo "Builds dist/cli/index.js and links the ag-unity command with npm link."
    ;;
  * )
    warn "Unknown option: $1"
    echo "Usage: ./setup.sh"
    exit 1
    ;;
esac
