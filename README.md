# GitLab Support Scripts Collection 📚

[![CI](https://github.com/username/gitlab-support-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/username/gitlab-support-scripts/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-red.svg)](https://www.ruby-lang.org/)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/username/gitlab-support-scripts)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![GitLab Mirror](https://img.shields.io/badge/gitlab-mirror-orange.svg)](https://gitlab.com/username/gitlab-support-scripts)
[![GitHub Release](https://img.shields.io/github/v/release/username/gitlab-support-scripts.svg)](https://github.com/username/gitlab-support-scripts/releases)
[![GitHub Issues](https://img.shields.io/github/issues/username/gitlab-support-scripts.svg)](https://github.com/username/gitlab-support-scripts/issues)
[![Test Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](#testing)

A collection of useful scripts for GitLab support and administration tasks.

## Scripts Included
- `gitlab-health-check.rb` - Check GitLab instance health
- `gitlab-db-analyzer.rb` - Analyze database performance
- `gitlab-redis-monitor.rb` - Monitor Redis metrics
- `gitlab-sidekiq-stats.rb` - Sidekiq queue analysis
- `gitlab-backup-verify.sh` - Verify backup integrity

## Usage

### GitLab Health Check
```bash
ruby scripts/gitlab-health-check.rb https://gitlab.example.com
```
Checks GitLab instance health including readiness, liveness, version, and database connectivity.

### Database Analyzer
```bash
ruby scripts/gitlab-db-analyzer.rb https://gitlab.example.com [access_token]
```
Analyzes database performance, slow queries, connection pool status, and table sizes.

### Redis Monitor
```bash
ruby scripts/gitlab-redis-monitor.rb https://gitlab.example.com [access_token]
```
Monitors Redis performance, memory usage, connection statistics, and key patterns.

### Sidekiq Statistics
```bash
ruby scripts/gitlab-sidekiq-stats.rb https://gitlab.example.com [access_token]
```
Analyzes Sidekiq queue performance, job statistics, worker performance, and failed jobs.

### Backup Verification
```bash
./scripts/gitlab-backup-verify.sh -d /path/to/backup/directory [-v] [-q]
```
Verifies backup integrity, structure, age, and configuration files.

Options:
- `-d DIR`: Backup directory path (required)
- `-v`: Verbose output
- `-q`: Quick check (skip detailed analysis)

**Note:** Scripts requiring GitLab API access need appropriate permissions. Admin access tokens are recommended for full functionality.

## Testing

A comprehensive test suite is included to verify script functionality:

### Run All Tests
```bash
./tests/run_tests.sh
```

### Run Specific Tests
```bash
./tests/run_tests.sh health-check     # Health check tests
./tests/run_tests.sh db-analyzer      # Database analyzer tests
./tests/run_tests.sh redis-monitor    # Redis monitor tests
./tests/run_tests.sh sidekiq-stats    # Sidekiq statistics tests
./tests/run_tests.sh backup-verify    # Backup verification tests
```

### Test Dependencies
- Ruby (with standard libraries)
- WEBrick gem (for mock server): `gem install webrick`
- Bash (for shell script tests)

### Test Coverage
- **Health Check**: API endpoint testing, error handling, network failures
- **Database Analyzer**: Query analysis, connection pool, authentication
- **Redis Monitor**: Memory usage, connection stats, key patterns
- **Sidekiq Statistics**: Queue analysis, job stats, worker performance
- **Backup Verification**: File integrity, structure validation, age checks

## Docker Usage

A Docker container is available for easy deployment and usage:

### Build the Container
```bash
docker build -t gitlab-support-scripts .
```

### Run Commands Directly
```bash
# Health check
docker run --rm gitlab-support-scripts gitlab-health-check https://gitlab.example.com

# Database analysis (with token)
docker run --rm gitlab-support-scripts gitlab-db-analyzer https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx

# Redis monitoring
docker run --rm gitlab-support-scripts gitlab-redis-monitor https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx

# Sidekiq statistics
docker run --rm gitlab-support-scripts gitlab-sidekiq-stats https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx

# Backup verification (mount backup directory)
docker run --rm -v /path/to/backups:/backups gitlab-support-scripts gitlab-backup-verify -d /backups -v
```

### Run Tests
```bash
# Run all tests
docker run --rm gitlab-support-scripts --test

# Run specific tests
docker run --rm gitlab-support-scripts run-tests health-check
```

### Interactive Mode
```bash
# Start container with shell access
docker run -it --rm gitlab-support-scripts bash

# Then run commands directly
gitlab-health-check https://gitlab.example.com
```

### Get Help
```bash
docker run --rm gitlab-support-scripts --help
```

### Docker Compose

For more complex deployments, use the provided `docker-compose.yml`:

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your GitLab URL and token
# GITLAB_URL=https://your-gitlab.com
# GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx

# Run one-off commands
docker-compose run --rm gitlab-support-scripts gitlab-health-check

# Start monitoring service (runs health checks every hour)
docker-compose --profile monitoring up -d gitlab-monitor

# View monitoring logs
docker-compose logs -f gitlab-monitor
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Write tests** for any new functionality
3. **Ensure all tests pass** with `./tests/run_tests.sh`
4. **Follow Ruby style conventions** (run `rubocop` if available)
5. **Update documentation** as needed
6. **Submit a pull request** with a clear description

### Development Setup

```bash
# Clone the repository
git clone https://github.com/username/gitlab-support-scripts.git
cd gitlab-support-scripts

# Make scripts executable
chmod +x scripts/*.rb scripts/*.sh tests/*.sh

# Run tests
./tests/run_tests.sh

# Test Docker build
docker build -t gitlab-support-scripts .
```

### Code Standards

- **Security First**: All scripts are for defensive security purposes only
- **Error Handling**: Graceful degradation and clear error messages
- **Documentation**: Update README.md and CLAUDE.md for significant changes
- **Testing**: Maintain 100% test coverage for critical functionality

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/username/gitlab-support-scripts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/username/gitlab-support-scripts/discussions)
- **GitLab Mirror**: [GitLab Repository](https://gitlab.com/username/gitlab-support-scripts)

## Development
This project is under active development.
