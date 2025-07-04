#!/bin/bash

# Test Runner for GitLab Support Scripts
# Runs all test suites and reports results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_SUITES=()

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

run_ruby_test() {
    local test_file="$1"
    local test_name="$2"
    
    log "Running $test_name..."
    echo "=" * 50
    
    if ruby "$test_file"; then
        log "✓ $test_name passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log "❌ $test_name failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_SUITES+=("$test_name")
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
}

run_bash_test() {
    local test_file="$1"
    local test_name="$2"
    
    log "Running $test_name..."
    echo "=" * 50
    
    if bash "$test_file"; then
        log "✓ $test_name passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log "❌ $test_name failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_SUITES+=("$test_name")
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
}

check_dependencies() {
    log "Checking test dependencies..."
    
    # Check for Ruby
    if ! command -v ruby &> /dev/null; then
        echo "❌ Ruby is not installed. Please install Ruby to run tests."
        exit 1
    fi
    
    # Check for required Ruby gems
    if ! ruby -e "require 'webrick'" 2>/dev/null; then
        echo "❌ WEBrick gem is not available. Please install it: gem install webrick"
        exit 1
    fi
    
    echo "✓ All dependencies are available"
}

run_all_tests() {
    log "Starting GitLab Support Scripts test suite..."
    echo "=" * 60
    
    check_dependencies
    
    # Ruby tests
    run_ruby_test "$SCRIPT_DIR/test_gitlab_health_check.rb" "GitLab Health Check Tests"
    run_ruby_test "$SCRIPT_DIR/test_gitlab_db_analyzer.rb" "GitLab Database Analyzer Tests"
    run_ruby_test "$SCRIPT_DIR/test_gitlab_redis_monitor.rb" "GitLab Redis Monitor Tests"
    run_ruby_test "$SCRIPT_DIR/test_gitlab_sidekiq_stats.rb" "GitLab Sidekiq Statistics Tests"
    
    # Bash tests
    run_bash_test "$SCRIPT_DIR/test_gitlab_backup_verify.sh" "GitLab Backup Verification Tests"
    
    # Summary
    echo "=" * 60
    log "Test Summary:"
    echo "  Total test suites: $TOTAL_TESTS"
    echo "  Passed: $PASSED_TESTS"
    echo "  Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo "  Result: ✓ All tests passed!"
        return 0
    else
        echo "  Result: ❌ Some tests failed"
        echo "  Failed suites:"
        for suite in "${FAILED_SUITES[@]}"; do
            echo "    - $suite"
        done
        return 1
    fi
}

run_specific_test() {
    local test_name="$1"
    
    case "$test_name" in
        "health-check"|"health")
            run_ruby_test "$SCRIPT_DIR/test_gitlab_health_check.rb" "GitLab Health Check Tests"
            ;;
        "db-analyzer"|"db")
            run_ruby_test "$SCRIPT_DIR/test_gitlab_db_analyzer.rb" "GitLab Database Analyzer Tests"
            ;;
        "redis-monitor"|"redis")
            run_ruby_test "$SCRIPT_DIR/test_gitlab_redis_monitor.rb" "GitLab Redis Monitor Tests"
            ;;
        "sidekiq-stats"|"sidekiq")
            run_ruby_test "$SCRIPT_DIR/test_gitlab_sidekiq_stats.rb" "GitLab Sidekiq Statistics Tests"
            ;;
        "backup-verify"|"backup")
            run_bash_test "$SCRIPT_DIR/test_gitlab_backup_verify.sh" "GitLab Backup Verification Tests"
            ;;
        *)
            echo "❌ Unknown test: $test_name"
            echo "Available tests: health-check, db-analyzer, redis-monitor, sidekiq-stats, backup-verify"
            exit 1
            ;;
    esac
}

show_usage() {
    echo "Usage: $0 [test_name]"
    echo ""
    echo "Run all tests:"
    echo "  $0"
    echo ""
    echo "Run specific test:"
    echo "  $0 health-check     # GitLab Health Check tests"
    echo "  $0 db-analyzer      # Database Analyzer tests"
    echo "  $0 redis-monitor    # Redis Monitor tests"
    echo "  $0 sidekiq-stats    # Sidekiq Statistics tests"
    echo "  $0 backup-verify    # Backup Verification tests"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help"
}

# Parse command line arguments
case "${1:-}" in
    ""|"all")
        run_all_tests
        exit $?
        ;;
    "-h"|"--help")
        show_usage
        exit 0
        ;;
    *)
        run_specific_test "$1"
        exit $?
        ;;
esac