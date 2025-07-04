#!/bin/bash

# GitLab Backup Verification Script
# Verifies the integrity and completeness of GitLab backups

set -e

BACKUP_DIR=""
VERBOSE=false
QUICK_CHECK=false

usage() {
    echo "Usage: $0 -d <backup_directory> [options]"
    echo "Options:"
    echo "  -d DIR    Backup directory path"
    echo "  -v        Verbose output"
    echo "  -q        Quick check (skip detailed analysis)"
    echo "  -h        Show this help"
    exit 1
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

verbose_log() {
    if [ "$VERBOSE" = true ]; then
        log "$1"
    fi
}

check_backup_structure() {
    log "Checking backup structure..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ Backup directory does not exist: $BACKUP_DIR"
        exit 1
    fi
    
    # Check for required backup files
    required_files=(
        "*_gitlab_backup.tar"
        "gitlab.rb"
        "gitlab-secrets.json"
    )
    
    for pattern in "${required_files[@]}"; do
        if ! ls "$BACKUP_DIR"/$pattern 1> /dev/null 2>&1; then
            echo "⚠️  Warning: No files matching pattern $pattern found"
        else
            verbose_log "✓ Found files matching $pattern"
        fi
    done
    
    echo "✓ Backup structure check completed"
}

verify_backup_integrity() {
    log "Verifying backup file integrity..."
    
    backup_files=$(find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -type f)
    
    if [ -z "$backup_files" ]; then
        echo "❌ No GitLab backup tar files found"
        exit 1
    fi
    
    for backup_file in $backup_files; do
        verbose_log "Checking: $(basename "$backup_file")"
        
        # Check if tar file is valid
        if tar -tf "$backup_file" > /dev/null 2>&1; then
            echo "✓ $(basename "$backup_file") - tar file is valid"
        else
            echo "❌ $(basename "$backup_file") - corrupted tar file"
            continue
        fi
        
        if [ "$QUICK_CHECK" = false ]; then
            # Extract and verify backup_information.yml
            if tar -xf "$backup_file" -O backup_information.yml > /dev/null 2>&1; then
                verbose_log "✓ backup_information.yml found"
            else
                echo "⚠️  Warning: backup_information.yml not found in $(basename "$backup_file")"
            fi
            
            # Check for database dump
            if tar -tf "$backup_file" | grep -q "db/database.sql"; then
                verbose_log "✓ Database dump found"
            else
                echo "⚠️  Warning: Database dump not found in $(basename "$backup_file")"
            fi
            
            # Check for repositories
            if tar -tf "$backup_file" | grep -q "repositories/"; then
                verbose_log "✓ Repositories directory found"
            else
                echo "⚠️  Warning: Repositories directory not found in $(basename "$backup_file")"
            fi
        fi
    done
    
    echo "✓ Backup integrity verification completed"
}

check_backup_age() {
    log "Checking backup age..."
    
    backup_files=$(find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -type f)
    current_time=$(date +%s)
    
    for backup_file in $backup_files; do
        file_time=$(stat -c %Y "$backup_file" 2>/dev/null || stat -f %m "$backup_file" 2>/dev/null || echo 0)
        age_hours=$(( (current_time - file_time) / 3600 ))
        
        if [ $age_hours -lt 24 ]; then
            echo "✓ $(basename "$backup_file") - Recent (${age_hours}h old)"
        elif [ $age_hours -lt 168 ]; then
            echo "⚠️  $(basename "$backup_file") - ${age_hours}h old (>1 day)"
        else
            echo "❌ $(basename "$backup_file") - ${age_hours}h old (>1 week)"
        fi
    done
    
    echo "✓ Backup age check completed"
}

check_configuration_files() {
    log "Checking configuration files..."
    
    # Check gitlab.rb
    if [ -f "$BACKUP_DIR/gitlab.rb" ]; then
        if [ -s "$BACKUP_DIR/gitlab.rb" ]; then
            echo "✓ gitlab.rb found and not empty"
        else
            echo "⚠️  Warning: gitlab.rb is empty"
        fi
    else
        echo "⚠️  Warning: gitlab.rb not found"
    fi
    
    # Check gitlab-secrets.json
    if [ -f "$BACKUP_DIR/gitlab-secrets.json" ]; then
        if [ -s "$BACKUP_DIR/gitlab-secrets.json" ]; then
            echo "✓ gitlab-secrets.json found and not empty"
        else
            echo "⚠️  Warning: gitlab-secrets.json is empty"
        fi
    else
        echo "⚠️  Warning: gitlab-secrets.json not found"
    fi
    
    echo "✓ Configuration files check completed"
}

analyze_backup_size() {
    log "Analyzing backup sizes..."
    
    backup_files=$(find "$BACKUP_DIR" -name "*_gitlab_backup.tar" -type f)
    
    for backup_file in $backup_files; do
        size=$(du -h "$backup_file" | cut -f1)
        echo "📊 $(basename "$backup_file"): $size"
    done
    
    total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    echo "📊 Total backup directory size: $total_size"
    
    echo "✓ Backup size analysis completed"
}

# Parse command line arguments
while getopts "d:vqh" opt; do
    case $opt in
        d) BACKUP_DIR="$OPTARG" ;;
        v) VERBOSE=true ;;
        q) QUICK_CHECK=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check if backup directory is provided
if [ -z "$BACKUP_DIR" ]; then
    echo "Error: Backup directory is required"
    usage
fi

# Main execution
log "Starting GitLab backup verification for: $BACKUP_DIR"
echo "======================================="

check_backup_structure
verify_backup_integrity
check_backup_age
check_configuration_files
analyze_backup_size

echo "======================================="
log "GitLab backup verification completed"