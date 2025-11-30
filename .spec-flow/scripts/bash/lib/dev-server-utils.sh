#!/usr/bin/env bash
# Dev Server Utilities for Spec-Flow Quality Gates
# Provides reusable functions for starting, checking, and stopping dev servers

# Dev server state
DEV_SERVER_PID=""
DEV_SERVER_STARTED=false
DEV_SERVER_PORT="${DEV_SERVER_PORT:-3000}"
DEV_SERVER_LOG="/tmp/dev-server-${DEV_SERVER_PORT}.log"
DEV_SERVER_PID_FILE="/tmp/optimize-server-pids.txt"

# Check if server is already running on a port
is_server_running() {
    local port="${1:-$DEV_SERVER_PORT}"
    local url="http://localhost:$port"

    if curl -sf -o /dev/null --connect-timeout 2 "$url" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Wait for server to become ready
wait_for_server() {
    local url="${1:-http://localhost:$DEV_SERVER_PORT}"
    local timeout="${2:-60}"
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if curl -sf -o /dev/null --connect-timeout 2 "$url" 2>/dev/null; then
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    return 1
}

# Start dev server if not already running
start_dev_server() {
    local port="${1:-$DEV_SERVER_PORT}"
    local timeout="${2:-60}"

    # Check if already running
    if is_server_running "$port"; then
        echo "Dev server already running on port $port"
        DEV_SERVER_STARTED=false
        return 0
    fi

    # Kill any stale processes on the port
    echo "Killing stale processes on port $port..."
    npx kill-port "$port" 2>/dev/null || true
    sleep 1

    # Detect project type and start appropriate server
    if [ -f "pnpm-lock.yaml" ]; then
        echo "Starting dev server with pnpm..."
        pnpm dev > "$DEV_SERVER_LOG" 2>&1 &
        DEV_SERVER_PID=$!
    elif [ -f "yarn.lock" ]; then
        echo "Starting dev server with yarn..."
        yarn dev > "$DEV_SERVER_LOG" 2>&1 &
        DEV_SERVER_PID=$!
    elif [ -f "package.json" ]; then
        echo "Starting dev server with npm..."
        npm run dev > "$DEV_SERVER_LOG" 2>&1 &
        DEV_SERVER_PID=$!
    else
        echo "No package.json found, cannot start dev server"
        return 1
    fi

    # Save PID for cleanup
    echo "$DEV_SERVER_PID" > "$DEV_SERVER_PID_FILE"

    # Wait for server to become ready
    echo "Waiting for dev server to start (timeout: ${timeout}s)..."
    if wait_for_server "http://localhost:$port" "$timeout"; then
        echo "Dev server ready on port $port (PID: $DEV_SERVER_PID)"
        DEV_SERVER_STARTED=true
        return 0
    else
        echo "Dev server failed to start within ${timeout}s"
        echo "Check logs: tail -f $DEV_SERVER_LOG"
        cleanup_dev_server
        return 1
    fi
}

# Stop dev server if we started it
cleanup_dev_server() {
    # Only cleanup if we started it
    if [ "$DEV_SERVER_STARTED" = true ]; then
        echo "Stopping dev server (PID: $DEV_SERVER_PID)..."

        if [ -n "$DEV_SERVER_PID" ]; then
            kill "$DEV_SERVER_PID" 2>/dev/null || true
        fi

        # Clean up port just to be safe
        npx kill-port "$DEV_SERVER_PORT" 2>/dev/null || true

        # Remove PID file
        rm -f "$DEV_SERVER_PID_FILE"

        DEV_SERVER_STARTED=false
        DEV_SERVER_PID=""
    fi
}

# Get dev server port from project config
detect_dev_port() {
    local port=3000

    # Check next.config.js for custom port
    if [ -f "next.config.js" ]; then
        local custom_port
        custom_port=$(grep -o 'port.*[0-9]\+' next.config.js 2>/dev/null | grep -o '[0-9]\+' | head -1)
        if [ -n "$custom_port" ]; then
            port=$custom_port
        fi
    fi

    # Check package.json scripts for port flag
    if [ -f "package.json" ]; then
        local script_port
        script_port=$(grep -o '\-p\s*[0-9]\+\|--port\s*[0-9]\+' package.json 2>/dev/null | grep -o '[0-9]\+' | head -1)
        if [ -n "$script_port" ]; then
            port=$script_port
        fi
    fi

    echo "$port"
}

# Setup cleanup trap - call this at the start of scripts using dev servers
setup_dev_server_cleanup_trap() {
    trap cleanup_dev_server EXIT INT TERM
}
