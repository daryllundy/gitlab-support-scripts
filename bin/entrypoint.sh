#!/bin/bash

# Entrypoint script for GitLab Support Scripts Docker container
# Provides help and routing to different scripts

set -e

show_help() {
    echo "GitLab Support Scripts Container"
    echo "================================"
    echo ""
    echo "Available commands:"
    echo ""
    echo "Health Monitoring:"
    echo "  gitlab-health-check <gitlab_url>"
    echo "    Example: gitlab-health-check https://gitlab.example.com"
    echo ""
    echo "Performance Analysis:"
    echo "  gitlab-db-analyzer <gitlab_url> [access_token]"
    echo "  gitlab-redis-monitor <gitlab_url> [access_token]"
    echo "  gitlab-sidekiq-stats <gitlab_url> [access_token]"
    echo "    Example: gitlab-db-analyzer https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx"
    echo ""
    echo "Backup Verification:"
    echo "  gitlab-backup-verify -d <backup_directory> [-v] [-q]"
    echo "    Example: gitlab-backup-verify -d /backups -v"
    echo ""
    echo "Testing:"
    echo "  run-tests [test_name]"
    echo "    Example: run-tests health-check"
    echo ""
    echo "Direct script access:"
    echo "  You can also run any script directly by name:"
    echo "  - gitlab-health-check"
    echo "  - gitlab-db-analyzer"
    echo "  - gitlab-redis-monitor"
    echo "  - gitlab-sidekiq-stats"
    echo "  - gitlab-backup-verify"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help"
    echo "  --version     Show version information"
    echo "  --test        Run all tests"
    echo ""
    echo "Notes:"
    echo "  - Scripts requiring GitLab API access need admin access tokens"
    echo "  - For backup verification, mount your backup directory as a volume"
    echo "  - Use -v flag for verbose output where supported"
}

show_version() {
    echo "GitLab Support Scripts v1.0.0"
    echo "Ruby version: $(ruby --version)"
    echo "Container OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')"
}

# Handle special cases
case "${1:-}" in
    "--help"|"-h"|"help")
        show_help
        exit 0
        ;;
    "--version"|"version")
        show_version
        exit 0
        ;;
    "--test"|"test")
        exec run-tests
        ;;
    "")
        show_help
        exit 0
        ;;
esac

# Check if the command is one of our wrapper scripts
COMMAND="$1"
shift

case "$COMMAND" in
    "gitlab-health-check")
        exec gitlab-health-check "$@"
        ;;
    "gitlab-db-analyzer")
        exec gitlab-db-analyzer "$@"
        ;;
    "gitlab-redis-monitor")
        exec gitlab-redis-monitor "$@"
        ;;
    "gitlab-sidekiq-stats")
        exec gitlab-sidekiq-stats "$@"
        ;;
    "gitlab-backup-verify")
        exec gitlab-backup-verify "$@"
        ;;
    "run-tests")
        exec run-tests "$@"
        ;;
    *)
        echo "❌ Unknown command: $COMMAND"
        echo ""
        echo "Run '$0 --help' for available commands."
        exit 1
        ;;
esac