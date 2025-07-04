#!/bin/bash

# Test suite for gitlab-backup-verify.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/../scripts/gitlab-backup-verify.sh"
TEST_COUNT=0
PASSED_COUNT=0

log_test() {
    echo "Test: $1"
    TEST_COUNT=$((TEST_COUNT + 1))
}

assert_success() {
    if [ $? -eq 0 ]; then
        echo "✓ $1"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo "❌ $1"
        exit 1
    fi
}

assert_failure() {
    if [ $? -ne 0 ]; then
        echo "✓ $1"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo "❌ $1"
        exit 1
    fi
}

assert_contains() {
    if echo "$1" | grep -q "$2"; then
        echo "✓ $3"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo "❌ $3"
        echo "Expected to find: $2"
        echo "In output: $1"
        exit 1
    fi
}

create_test_backup_dir() {
    local temp_dir=$(mktemp -d)
    
    # Create mock backup tar file
    local backup_file="$temp_dir/1640995200_2021_12_31_14.6.0_gitlab_backup.tar"
    
    # Create temporary directory for tar contents
    local tar_content=$(mktemp -d)
    echo "backup_created_at: 2021-12-31T00:00:00Z" > "$tar_content/backup_information.yml"
    echo "-- GitLab Database Dump" > "$tar_content/db/database.sql"
    mkdir -p "$tar_content/repositories"
    echo "mock repo data" > "$tar_content/repositories/repo1.git"
    
    # Create tar file
    (cd "$tar_content" && tar -cf "$backup_file" .)
    rm -rf "$tar_content"
    
    # Create configuration files
    echo 'external_url "https://gitlab.example.com"' > "$temp_dir/gitlab.rb"
    echo '{"db_key_base": "secret_key"}' > "$temp_dir/gitlab-secrets.json"
    
    echo "$temp_dir"
}

create_corrupted_backup_dir() {
    local temp_dir=$(mktemp -d)
    
    # Create corrupted backup file
    echo "corrupted data" > "$temp_dir/1640995200_2021_12_31_14.6.0_gitlab_backup.tar"
    
    echo "$temp_dir"
}

create_empty_backup_dir() {
    local temp_dir=$(mktemp -d)
    # Empty directory
    echo "$temp_dir"
}

run_tests() {
    echo "Running GitLab Backup Verification tests..."
    echo "=" * 40
    
    test_help_option
    test_missing_backup_directory
    test_nonexistent_backup_directory
    test_successful_backup_verification
    test_corrupted_backup_file
    test_empty_backup_directory
    test_verbose_output
    test_quick_check_option
    test_backup_age_check
    test_missing_config_files
    
    echo
    echo "=" * 40
    echo "Backup Verification Tests: $PASSED_COUNT/$TEST_COUNT passed"
    
    if [ $PASSED_COUNT -eq $TEST_COUNT ]; then
        echo "All tests passed! ✓"
        return 0
    else
        echo "Some tests failed! ❌"
        return 1
    fi
}

test_help_option() {
    log_test "Help option"
    
    output=$("$BACKUP_SCRIPT" -h 2>&1) || true
    assert_contains "$output" "Usage:" "Should show usage information"
}

test_missing_backup_directory() {
    log_test "Missing backup directory argument"
    
    output=$("$BACKUP_SCRIPT" 2>&1) || true
    assert_contains "$output" "Error: Backup directory is required" "Should require backup directory"
}

test_nonexistent_backup_directory() {
    log_test "Nonexistent backup directory"
    
    output=$("$BACKUP_SCRIPT" -d "/nonexistent/directory" 2>&1) || true
    assert_contains "$output" "❌ Backup directory does not exist" "Should detect missing directory"
}

test_successful_backup_verification() {
    log_test "Successful backup verification"
    
    temp_dir=$(create_test_backup_dir)
    
    output=$("$BACKUP_SCRIPT" -d "$temp_dir" 2>&1)
    assert_success "Should complete successfully"
    
    assert_contains "$output" "✓ Backup structure check completed" "Should complete structure check"
    assert_contains "$output" "✓.*tar file is valid" "Should verify tar file"
    assert_contains "$output" "✓ gitlab.rb found and not empty" "Should find gitlab.rb"
    assert_contains "$output" "✓ gitlab-secrets.json found and not empty" "Should find gitlab-secrets.json"
    assert_contains "$output" "✓ Backup integrity verification completed" "Should complete integrity check"
    
    rm -rf "$temp_dir"
}

test_corrupted_backup_file() {
    log_test "Corrupted backup file"
    
    temp_dir=$(create_corrupted_backup_dir)
    
    output=$("$BACKUP_SCRIPT" -d "$temp_dir" 2>&1)
    assert_success "Should complete with warnings"
    
    assert_contains "$output" "❌.*corrupted tar file" "Should detect corrupted tar file"
    
    rm -rf "$temp_dir"
}

test_empty_backup_directory() {
    log_test "Empty backup directory"
    
    temp_dir=$(create_empty_backup_dir)
    
    output=$("$BACKUP_SCRIPT" -d "$temp_dir" 2>&1) || true
    assert_contains "$output" "❌ No GitLab backup tar files found" "Should detect no backup files"
    
    rm -rf "$temp_dir"
}

test_verbose_output() {
    log_test "Verbose output option"
    
    temp_dir=$(create_test_backup_dir)
    
    output=$("$BACKUP_SCRIPT" -d "$temp_dir" -v 2>&1)
    assert_success "Should complete successfully with verbose output"
    
    assert_contains "$output" "✓ Found files matching" "Should show verbose messages"
    
    rm -rf "$temp_dir"
}

test_quick_check_option() {
    log_test "Quick check option"
    
    temp_dir=$(create_test_backup_dir)
    
    output=$("$BACKUP_SCRIPT" -d "$temp_dir" -q 2>&1)
    assert_success "Should complete successfully with quick check"
    
    # Quick check should still verify tar file but skip detailed analysis
    assert_contains "$output" "✓.*tar file is valid" "Should verify tar file in quick mode"
    
    rm -rf "$temp_dir"
}

test_backup_age_check() {
    log_test "Backup age check"
    
    temp_dir=$(create_test_backup_dir)
    
    output=$("$BACKUP_SCRIPT" -d "$temp_dir" 2>&1)
    assert_success "Should complete successfully"
    
    # Should show age information (will be old since we're using a 2021 timestamp)
    assert_contains "$output" "old" "Should show backup age"
    
    rm -rf "$temp_dir"
}

test_missing_config_files() {
    log_test "Missing configuration files"
    
    temp_dir=$(mktemp -d)
    
    # Create backup tar but no config files
    local backup_file="$temp_dir/1640995200_2021_12_31_14.6.0_gitlab_backup.tar"
    echo "mock backup" > "$backup_file"
    
    output=$("$BACKUP_SCRIPT" -d "$temp_dir" 2>&1)
    assert_success "Should complete with warnings"
    
    assert_contains "$output" "⚠️.*gitlab.rb not found" "Should detect missing gitlab.rb"
    assert_contains "$output" "⚠️.*gitlab-secrets.json not found" "Should detect missing gitlab-secrets.json"
    
    rm -rf "$temp_dir"
}

# Run all tests
run_tests
exit $?