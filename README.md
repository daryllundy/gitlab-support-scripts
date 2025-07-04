# GitLab Support Scripts Collection 📚

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

## Development
This project is under active development.
