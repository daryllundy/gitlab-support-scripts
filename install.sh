#!/bin/bash

# GitLab Support Scripts Installation Script
# Sets up the environment and makes scripts executable

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_dependencies() {
    log "Checking dependencies..."
    
    # Check for Ruby
    if ! command -v ruby &> /dev/null; then
        echo "❌ Ruby is not installed. Please install Ruby first."
        echo "   On Ubuntu/Debian: sudo apt-get install ruby"
        echo "   On macOS: brew install ruby"
        echo "   On CentOS/RHEL: sudo yum install ruby"
        exit 1
    else
        ruby_version=$(ruby --version)
        echo "✓ Ruby found: $ruby_version"
    fi
    
    # Check for required Ruby gems
    log "Checking Ruby standard libraries..."
    ruby -e "require 'net/http'; require 'json'; require 'uri'" 2>/dev/null || {
        echo "❌ Required Ruby libraries not available"
        exit 1
    }
    echo "✓ Required Ruby libraries available"
    
    # Check for bash
    if ! command -v bash &> /dev/null; then
        echo "❌ Bash is not installed"
        exit 1
    else
        echo "✓ Bash found: $(bash --version | head -n1)"
    fi
}

make_scripts_executable() {
    log "Making scripts executable..."
    
    if [ ! -d "$SCRIPTS_DIR" ]; then
        echo "❌ Scripts directory not found: $SCRIPTS_DIR"
        exit 1
    fi
    
    # Make Ruby scripts executable
    for script in "$SCRIPTS_DIR"/*.rb; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            echo "✓ Made executable: $(basename "$script")"
        fi
    done
    
    # Make shell scripts executable
    for script in "$SCRIPTS_DIR"/*.sh; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            echo "✓ Made executable: $(basename "$script")"
        fi
    done
}

create_symlinks() {
    log "Creating symbolic links..."
    
    # Ask user if they want to create symlinks in /usr/local/bin
    read -p "Create symbolic links in /usr/local/bin? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ ! -w "/usr/local/bin" ]; then
            echo "❌ Cannot write to /usr/local/bin. Run with sudo or skip this step."
            return
        fi
        
        for script in "$SCRIPTS_DIR"/*.rb "$SCRIPTS_DIR"/*.sh; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                link_name="${script_name%.*}"  # Remove extension
                
                if [ -L "/usr/local/bin/$link_name" ]; then
                    rm "/usr/local/bin/$link_name"
                fi
                
                ln -s "$script" "/usr/local/bin/$link_name"
                echo "✓ Created symlink: /usr/local/bin/$link_name -> $script"
            fi
        done
        
        echo "✓ Scripts can now be run from anywhere using their names (without extensions)"
    else
        echo "⚠️  Skipping symlink creation. Scripts must be run from the scripts directory."
    fi
}

verify_installation() {
    log "Verifying installation..."
    
    # Test each script
    for script in "$SCRIPTS_DIR"/*.rb; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            if "$script" --help &>/dev/null || "$script" -h &>/dev/null || [ $? -eq 1 ]; then
                echo "✓ $script_name appears to be working"
            else
                echo "⚠️  $script_name may have issues (this is expected if no arguments provided)"
            fi
        fi
    done
    
    # Test shell scripts
    for script in "$SCRIPTS_DIR"/*.sh; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            if "$script" -h &>/dev/null || [ $? -eq 1 ]; then
                echo "✓ $script_name appears to be working"
            else
                echo "⚠️  $script_name may have issues (this is expected if no arguments provided)"
            fi
        fi
    done
}

show_usage_examples() {
    log "Usage examples:"
    echo ""
    echo "Health Check:"
    echo "  ruby $SCRIPTS_DIR/gitlab-health-check.rb https://gitlab.example.com"
    echo ""
    echo "Database Analysis:"
    echo "  ruby $SCRIPTS_DIR/gitlab-db-analyzer.rb https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx"
    echo ""
    echo "Redis Monitoring:"
    echo "  ruby $SCRIPTS_DIR/gitlab-redis-monitor.rb https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx"
    echo ""
    echo "Sidekiq Statistics:"
    echo "  ruby $SCRIPTS_DIR/gitlab-sidekiq-stats.rb https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx"
    echo ""
    echo "Backup Verification:"
    echo "  $SCRIPTS_DIR/gitlab-backup-verify.sh -d /path/to/backup/directory"
    echo ""
    echo "For more information, see the README.md file."
}

# Main installation process
log "Starting GitLab Support Scripts installation..."
echo "============================================="

check_dependencies
make_scripts_executable
create_symlinks
verify_installation
show_usage_examples

echo "============================================="
log "Installation completed successfully!"
echo ""
echo "📝 Important notes:"
echo "   - Scripts requiring GitLab API access need appropriate admin tokens"
echo "   - See README.md for detailed usage instructions"
echo "   - Test scripts with your GitLab instance before production use"