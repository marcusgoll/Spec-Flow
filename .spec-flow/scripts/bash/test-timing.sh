#!/bin/bash
#
# test-timing.sh - Test timing functions for workflow state
#
# Tests all timing functions to ensure they work correctly before
# using them in production workflows.

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Testing Workflow Timing Functions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Source timing functions
source .spec-flow/scripts/bash/workflow-state.sh

# Create test feature directory
TEST_DIR="specs/999-test-timing"
echo "Creating test feature directory: $TEST_DIR"
mkdir -p "$TEST_DIR"

# Initialize workflow state
echo "Initializing workflow state..."
initialize_workflow_state "$TEST_DIR" "999-test-timing" "Test Timing Feature" "test-timing"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Phase Timing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test spec-flow phase timing
echo "Starting spec-flow phase..."
start_phase_timing "$TEST_DIR" "spec-flow"
sleep 2
echo "Completing spec-flow phase (2 seconds elapsed)..."
complete_phase_timing "$TEST_DIR" "spec-flow"

# Verify spec-flow timing
SPEC_DURATION=$(yq eval '.workflow.phase_timing."spec-flow".duration_seconds' "$TEST_DIR/workflow-state.yaml")
echo "✅ Spec-flow duration: $SPEC_DURATION seconds"

if [ "$SPEC_DURATION" -ge 2 ] && [ "$SPEC_DURATION" -le 3 ]; then
  echo "✅ Duration is correct (2-3 seconds expected)"
else
  echo "❌ Duration unexpected: $SPEC_DURATION (expected 2-3)"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Sub-Phase Timing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test optimize phase with sub-phases
echo "Starting optimize phase..."
start_phase_timing "$TEST_DIR" "optimize"

echo "Starting performance sub-phase..."
start_sub_phase_timing "$TEST_DIR" "optimize" "performance"
sleep 1
echo "Completing performance sub-phase (1 second elapsed)..."
complete_sub_phase_timing "$TEST_DIR" "optimize" "performance"

echo "Starting security sub-phase..."
start_sub_phase_timing "$TEST_DIR" "optimize" "security"
sleep 1
echo "Completing security sub-phase (1 second elapsed)..."
complete_sub_phase_timing "$TEST_DIR" "optimize" "security"

echo "Completing optimize phase..."
complete_phase_timing "$TEST_DIR" "optimize"

# Verify sub-phase timing
PERF_DURATION=$(yq eval '.workflow.phase_timing."optimize".sub_phases."performance".duration_seconds' "$TEST_DIR/workflow-state.yaml")
SEC_DURATION=$(yq eval '.workflow.phase_timing."optimize".sub_phases."security".duration_seconds' "$TEST_DIR/workflow-state.yaml")

echo "✅ Performance sub-phase duration: $PERF_DURATION seconds"
echo "✅ Security sub-phase duration: $SEC_DURATION seconds"

if [ "$PERF_DURATION" -ge 1 ] && [ "$PERF_DURATION" -le 2 ]; then
  echo "✅ Performance duration is correct"
else
  echo "❌ Performance duration unexpected: $PERF_DURATION"
  exit 1
fi

if [ "$SEC_DURATION" -ge 1 ] && [ "$SEC_DURATION" -le 2 ]; then
  echo "✅ Security duration is correct"
else
  echo "❌ Security duration unexpected: $SEC_DURATION"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Manual Gate Timing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test manual gate timing
echo "Creating manual gate (preview)..."
update_manual_gate "$TEST_DIR" "preview" "pending"
sleep 2
echo "Approving manual gate (2 seconds wait)..."
update_manual_gate "$TEST_DIR" "preview" "approved" "test-user"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Workflow Metrics Calculation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Calculating workflow metrics..."
calculate_workflow_metrics "$TEST_DIR"

# Verify metrics
TOTAL_DURATION=$(yq eval '.workflow.metrics.total_duration_seconds' "$TEST_DIR/workflow-state.yaml")
ACTIVE_WORK=$(yq eval '.workflow.metrics.active_work_seconds' "$TEST_DIR/workflow-state.yaml")
MANUAL_WAIT=$(yq eval '.workflow.metrics.manual_wait_seconds' "$TEST_DIR/workflow-state.yaml")
PHASES_COUNT=$(yq eval '.workflow.metrics.phases_count' "$TEST_DIR/workflow-state.yaml")

echo "✅ Total duration: $TOTAL_DURATION seconds"
echo "✅ Active work: $ACTIVE_WORK seconds"
echo "✅ Manual wait: $MANUAL_WAIT seconds"
echo "✅ Phases count: $PHASES_COUNT"

# Validate calculations
# Total = spec-flow (2s) + optimize (2s) = 4s
# Manual wait should be ~2s
# Active = Total - Manual = ~2s

if [ "$PHASES_COUNT" -ne 2 ]; then
  echo "❌ Phases count incorrect: $PHASES_COUNT (expected 2)"
  exit 1
fi

if [ "$MANUAL_WAIT" -ge 2 ] && [ "$MANUAL_WAIT" -le 3 ]; then
  echo "✅ Manual wait time is correct"
else
  echo "❌ Manual wait time unexpected: $MANUAL_WAIT (expected 2-3)"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: Duration Formatting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test duration formatting
echo "Testing format_duration function..."
TEST_30=$(format_duration 30)
TEST_90=$(format_duration 90)
TEST_3661=$(format_duration 3661)

echo "✅ 30 seconds → $TEST_30"
echo "✅ 90 seconds → $TEST_90"
echo "✅ 3661 seconds → $TEST_3661"

if [ "$TEST_30" = "30s" ]; then
  echo "✅ Format correct for seconds"
else
  echo "❌ Format incorrect: $TEST_30 (expected 30s)"
  exit 1
fi

if [ "$TEST_90" = "1m 30s" ]; then
  echo "✅ Format correct for minutes"
else
  echo "❌ Format incorrect: $TEST_90 (expected 1m 30s)"
  exit 1
fi

if [ "$TEST_3661" = "1h 1m" ]; then
  echo "✅ Format correct for hours"
else
  echo "❌ Format incorrect: $TEST_3661 (expected 1h 1m)"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6: Workflow Summary Display"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Displaying workflow summary..."
display_workflow_summary "$TEST_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 All Tests Passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Timing functions are working correctly."
echo ""
echo "Cleanup:"
echo "  Test directory: $TEST_DIR"
echo "  To remove: rm -rf $TEST_DIR"
echo ""
echo "Next steps:"
echo "  1. Run a real /feature workflow to test integration"
echo "  2. Check that timing summary appears at the end"
echo "  3. Verify all phases are tracked correctly"
echo ""
