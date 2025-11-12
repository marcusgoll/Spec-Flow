#!/usr/bin/env bash
# Agent Auto-Route Hook Wrapper
# Pipes stdin to TypeScript hook for processing

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HOOK_DIR"

# Pipe stdin to TypeScript hook
cat | npx tsx agent-auto-route.ts
