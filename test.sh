#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HLR="$SCRIPT_DIR/hlrunner"
TEST_STACKS_DIR="$SCRIPT_DIR/teststacks"
SERVICES_DIR="$SCRIPT_DIR/../services"

export HLR_DATA_DIR="$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    FAILED=$((FAILED + 1))
}

info() {
    echo -e "${YELLOW}ℹ INFO:${NC} $1"
}

cleanup() {
    info "Cleaning up test stacks..."
    rm -rf "$TEST_STACKS_DIR"
}

setup() {
    cleanup
    mkdir -p "$TEST_STACKS_DIR/mystack"
    cat > "$TEST_STACKS_DIR/mystack/compose.yaml" << 'EOF'
services:
  nginx:
    image: nginx:latest
EOF
    cat > "$TEST_STACKS_DIR/mystack/.env" << 'EOF'
STACK_NAME=mystack
EOF
    mkdir -p "$TEST_STACKS_DIR/disabled"
    mkdir -p "$TEST_STACKS_DIR/nobuildfile"
    mkdir -p "$TEST_STACKS_DIR/imageonly"
    cat > "$TEST_STACKS_DIR/imageonly/compose.yaml" << 'EOF'
services:
  nginx:
    image: nginx:latest
EOF
    mkdir -p "$TEST_STACKS_DIR/hasbuild"
    cat > "$TEST_STACKS_DIR/hasbuild/compose.yaml" << 'EOF'
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
EOF
}

run_test() {
    local test_name=$1
    local cmd=$2
    local expected_contains=$3
    local expected_not_contains=$4

    info "Running: $test_name"

    output=$(eval "$cmd" 2>&1 || true)

    if echo "$output" | grep -q "$expected_contains"; then
        if [ -n "$expected_not_contains" ] && echo "$output" | grep -q "$expected_not_contains"; then
            fail "$test_name - found unexpected: $expected_not_contains"
        else
            pass "$test_name"
        fi
    else
        fail "$test_name - expected: $expected_contains, got: $output"
    fi
}

echo "========================================"
echo "HLRunner Test Suite"
echo "========================================"
echo ""

setup

echo "--- Test 1: Help command ---"
run_test "Help displays available commands" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR" \
    "hlrunner <command>"

echo ""
echo "--- Test 2: List command with valid stack ---"
run_test "List finds mystack" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR list" \
    "mystack"

echo ""
echo "--- Test 3: List command finds correct count ---"
run_test "List shows 3 stacks" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR list" \
    "Found 3 Stack"

echo ""
echo "--- Test 4: Unknown command ---"
run_test "Unknown command shows error" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR unknowncmd 2>&1" \
    "Unknown command"

echo ""
echo "--- Test 5: Build command (stack exists, docker not required) ---"
run_test "Build finds compose file" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR build mystack 2>&1" \
    "docker: not found"

echo ""
echo "--- Test 6: Pull command (stack exists) ---"
run_test "Pull finds compose file" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR pull mystack 2>&1" \
    "docker: not found"

echo ""
echo "--- Test 7: Up command ---"
run_test "Up finds compose file" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR up mystack 2>&1" \
    "docker: not found"

echo ""
echo "--- Test 8: Down command ---"
run_test "Down finds compose file" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR down mystack 2>&1" \
    "docker: not found"

echo ""
echo "--- Test 9: Logs command ---"
run_test "Logs finds compose file" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR logs mystack 2>&1" \
    "docker: not found"

echo ""
echo "--- Test 10: Upgrade command ---"
run_test "Upgrade finds compose file" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR upgrade mystack 2>&1" \
    "docker: not found"

echo ""
echo "--- Test 11: Non-existent stack ---"
run_test "Non-existent stack shows error" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR up nonexistent 2>&1" \
    "has no compose file"

echo ""
echo "--- Test 12: Empty stacks path ---"
mkdir -p /tmp/emptytestdir
run_test "Empty directory shows error" \
    "HLR_STACKS_PATH=/tmp/emptytestdir $HLR list 2>&1 || true" \
    "No Stacks Found"

echo ""
echo "--- Test 13: Invalid path ---"
run_test "Invalid path shows error" \
    "HLR_STACKS_PATH=/nonexistent/path $HLR list 2>&1 || true" \
    "does not exist"

echo ""
echo "--- Test 14: List with relative path ---"
mkdir -p "$TEST_STACKS_DIR/relstack"
echo "services: {}" > "$TEST_STACKS_DIR/relstack/compose.yaml"
run_test "Relative path works" \
    "cd $TEST_STACKS_DIR && HLR_STACKS_PATH=./relstack $HLR list 2>&1" \
    "relstack"

echo ""
echo "--- Test 15: Build command appears in help ---"
run_test "Build in help text" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR 2>&1" \
    "build <stack>"

echo ""
echo "--- Test 16: Init command ---"
run_test "Init command exists" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR init testnew 2>&1" \
    "created successfully"

echo ""
echo "--- Test 17: Test with stacks directory ---"
run_test "Stacks directory works" \
    "HLR_STACKS_PATH=/workspace/stacks $HLR list 2>&1" \
    "web"

echo ""
echo "--- Test 18: Upgrade detects image-only stack (pull) ---"
run_test "Upgrade for image stack uses pull" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR upgrade imageonly 2>&1" \
    "Pulling latest images"

echo ""
echo "--- Test 19: Upgrade detects build context (build) ---"
run_test "Upgrade for build stack uses build" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR upgrade hasbuild 2>&1" \
    "Building (with pull)"

echo ""
echo "--- Test 20: Upgradeall uses smart detection ---"
run_test "Upgradeall uses build for build stacks" \
    "HLR_STACKS_PATH=$TEST_STACKS_DIR $HLR upgradeall 2>&1" \
    "Building (with pull)"

echo ""
echo "--- Test 21: Separate data directory (HLR_DATA_DIR) ---"
TEMP_DATA_DIR=$(mktemp -d)
TEMP_BIN_DIR=$(mktemp -d)
cp "$SCRIPT_DIR/hlrunner" "$TEMP_BIN_DIR/hlrunner"
cp -r "$SCRIPT_DIR/lib" "$TEMP_DATA_DIR/"
cp -r "$SCRIPT_DIR/templates" "$TEMP_DATA_DIR/"
chmod +x "$TEMP_BIN_DIR/hlrunner"
run_test "Works with HLR_DATA_DIR pointing to different location" \
    "HLR_DATA_DIR=$TEMP_DATA_DIR HLR_STACKS_PATH=$TEST_STACKS_DIR $TEMP_BIN_DIR/hlrunner list 2>&1" \
    "mystack"
rm -rf "$TEMP_DATA_DIR" "$TEMP_BIN_DIR"

echo ""
echo "--- Test 22: Default XDG_DATA_HOME location ---"
TEMP_HOME=$(mktemp -d)
TEMP_XDG_DATA="$TEMP_HOME/.local/share/hlrunner"
mkdir -p "$TEMP_XDG_DATA"
cp -r "$SCRIPT_DIR/lib" "$TEMP_XDG_DATA/"
cp -r "$SCRIPT_DIR/templates" "$TEMP_XDG_DATA/"
TEMP_BIN_DIR=$(mktemp -d)
cp "$SCRIPT_DIR/hlrunner" "$TEMP_BIN_DIR/hlrunner"
chmod +x "$TEMP_BIN_DIR/hlrunner"
run_test "Works with default XDG_DATA_HOME (~/.local/share/hlrunner)" \
    "HOME=$TEMP_HOME PATH=$TEMP_BIN_DIR:\$PATH HLR_STACKS_PATH=$TEST_STACKS_DIR $TEMP_BIN_DIR/hlrunner list 2>&1" \
    "mystack"
rm -rf "$TEMP_HOME" "$TEMP_BIN_DIR"

echo ""
echo "--- Test 23: XDG_DATA_HOME set to custom location ---"
TEMP_DATA_DIR=$(mktemp -d)
TEMP_BIN_DIR=$(mktemp -d)
cp "$SCRIPT_DIR/hlrunner" "$TEMP_BIN_DIR/hlrunner"
chmod +x "$TEMP_BIN_DIR/hlrunner"
run_test "Works with XDG_DATA_HOME set" \
    "XDG_DATA_HOME=$TEMP_DATA_DIR PATH=$TEMP_BIN_DIR:\$PATH HLR_STACKS_PATH=$TEST_STACKS_DIR $TEMP_BIN_DIR/hlrunner list 2>&1" \
    "mystack"
rm -rf "$TEMP_DATA_DIR" "$TEMP_BIN_DIR"

echo ""
echo "--- Test 24: Script-relative fallback when no XDG ---"
TEMP_DATA_DIR=$(mktemp -d)
cp -r "$SCRIPT_DIR/lib" "$TEMP_DATA_DIR/lib"
cp -r "$SCRIPT_DIR/templates" "$TEMP_DATA_DIR/templates"
cp "$SCRIPT_DIR/hlrunner" "$TEMP_DATA_DIR/hlrunner"
chmod +x "$TEMP_DATA_DIR/hlrunner"
run_test "Works script-relative when no HOME set" \
    "HOME=/nonexistent XDG_DATA_HOME= HLR_STACKS_PATH=$TEST_STACKS_DIR $TEMP_DATA_DIR/hlrunner list 2>&1" \
    "mystack"
rm -rf "$TEMP_DATA_DIR"

echo ""
echo "--- Test 25: Init with separate data directory ---"
TEMP_DATA_DIR=$(mktemp -d)
TEMP_BIN_DIR=$(mktemp -d)
cp "$SCRIPT_DIR/hlrunner" "$TEMP_BIN_DIR/hlrunner"
cp -r "$SCRIPT_DIR/lib" "$TEMP_DATA_DIR/"
cp -r "$SCRIPT_DIR/templates" "$TEMP_DATA_DIR/"
chmod +x "$TEMP_BIN_DIR/hlrunner"
TEST_INIT_DIR=$(mktemp -d)
run_test "Init command works with HLR_DATA_DIR" \
    "HLR_DATA_DIR=$TEMP_DATA_DIR HLR_STACKS_PATH=$TEST_INIT_DIR $TEMP_BIN_DIR/hlrunner init newstack 2>&1" \
    "created successfully"
rm -rf "$TEMP_DATA_DIR" "$TEMP_BIN_DIR" "$TEST_INIT_DIR"

echo ""
echo "--- Test 26: Portable use (drop in PATH) ---"
TEMP_DATA_DIR=$(mktemp -d)
TEMP_BIN_DIR=$(mktemp -d)
mkdir -p "$TEMP_BIN_DIR"
cp "$SCRIPT_DIR/hlrunner" "$TEMP_BIN_DIR/hlrunner"
cp -r "$SCRIPT_DIR/lib" "$TEMP_DATA_DIR/"
cp -r "$SCRIPT_DIR/templates" "$TEMP_DATA_DIR/"
chmod +x "$TEMP_BIN_DIR/hlrunner"
run_test "Works when dropped in PATH (portable mode)" \
    "HOME=/nonexistent XDG_DATA_HOME= PATH=$TEMP_BIN_DIR:\$PATH HLR_STACKS_PATH=$TEST_STACKS_DIR hlrunner list 2>&1" \
    "mystack"
rm -rf "$TEMP_DATA_DIR" "$TEMP_BIN_DIR"

echo ""
echo "========================================"
echo "Test Results: $PASSED passed, $FAILED failed"
echo "========================================"

cleanup

if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0
