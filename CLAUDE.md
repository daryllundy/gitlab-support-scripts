# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of GitLab support and administration scripts written primarily in Ruby. The project is designed to help with GitLab instance monitoring, performance analysis, and maintenance tasks.

## Project Structure

```
scripts/
├── gitlab-health-check.rb     # API health monitoring (in development)
├── gitlab-db-analyzer.rb      # Database query analysis (planned)
├── gitlab-redis-monitor.rb    # Redis performance monitoring (planned)
├── gitlab-sidekiq-stats.rb    # Sidekiq queue analysis (planned)
└── gitlab-backup-verify.sh    # Backup validation (planned)
```

## Development Status

This project is in early development. Currently only `gitlab-health-check.rb` exists as a basic stub. The remaining scripts are planned but not yet implemented (see tasks.md for the roadmap).

## Script Architecture

Each script is designed to be:
- **Standalone**: Can be run independently without dependencies on other scripts
- **Command-line focused**: Designed for direct execution with command-line arguments
- **Ruby-based**: Primary language is Ruby for most scripts (except shell scripts like backup verification)
- **GitLab-specific**: Each script targets specific GitLab components or functions

## Running Scripts

Scripts are executed directly from the command line:

```bash
# Run health check (accepts GitLab URL as argument)
ruby scripts/gitlab-health-check.rb http://your-gitlab-instance.com

# Default to localhost if no URL provided
ruby scripts/gitlab-health-check.rb
```

## Dependencies

- Ruby (no Gemfile or specific version requirements specified yet)
- Standard Ruby libraries (net/http, json)
- Scripts expect to connect to GitLab instances via HTTP/HTTPS

## Key Implementation Notes

- Scripts use Ruby classes with descriptive names (e.g., `GitLabHealthCheck`)
- Each script includes a main execution block with `if __FILE__ == $0`
- Command-line arguments are handled via `ARGV`
- Scripts are designed for GitLab support/administration (defensive security purposes)