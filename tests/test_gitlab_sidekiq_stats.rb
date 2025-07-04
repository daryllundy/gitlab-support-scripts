#!/usr/bin/env ruby

# Test suite for gitlab-sidekiq-stats.rb

require_relative 'test_helper'
require_relative '../scripts/gitlab-sidekiq-stats'

class TestGitLabSidekiqStats
  def initialize
    @helper = TestHelper.new
    @test_count = 0
    @passed_count = 0
  end
  
  def run_tests
    puts "Running GitLab Sidekiq Statistics tests..."
    puts "=" * 40
    
    setup_mock_server
    
    begin
      test_successful_sidekiq_analysis
      test_sidekiq_health_check
      test_queue_statistics
      test_job_statistics
      test_worker_performance
      test_failed_jobs_analysis
      test_failure_rate_calculation
      test_authentication_required
      test_network_error_handling
      
      puts "\n" + "=" * 40
      puts "Sidekiq Statistics Tests: #{@passed_count}/#{@test_count} passed"
      return @passed_count == @test_count
    ensure
      @helper.stop_mock_server
    end
  end
  
  private
  
  def setup_mock_server
    @helper.start_mock_server
    
    # Add Sidekiq stats endpoints
    MockGitLabResponses.sidekiq_stats_responses.each do |path, response|
      @helper.add_mock_response(path, **response)
    end
  end
  
  def test_successful_sidekiq_analysis
    @test_count += 1
    puts "\nTest: Successful Sidekiq analysis"
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "✓ Running (running)", "Sidekiq health check should pass")
    @helper.assert_includes(output[:stdout], "✓ Found 2 queues", "Should show queue count")
    @helper.assert_includes(output[:stdout], "✓ Jobs processed: 1000", "Should show job stats")
    @helper.assert_includes(output[:stdout], "✓ Active workers: 1", "Should show worker count")
    @helper.assert_includes(output[:stdout], "Sidekiq analysis completed", "Should complete successfully")
    
    @passed_count += 1
  end
  
  def test_sidekiq_health_check
    @test_count += 1
    puts "\nTest: Sidekiq health check"
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "Processes: 2", "Should show process count")
    @helper.assert_includes(output[:stdout], "Busy workers: 5", "Should show busy workers")
    @helper.assert_includes(output[:stdout], "Queue latency: 0.5s", "Should show queue latency")
    
    @passed_count += 1
  end
  
  def test_queue_statistics
    @test_count += 1
    puts "\nTest: Queue statistics"
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "Total queued jobs: 15", "Should show total queued jobs")
    @helper.assert_includes(output[:stdout], "default: 10 jobs", "Should show default queue")
    @helper.assert_includes(output[:stdout], "mailers: 5 jobs", "Should show mailers queue")
    
    @passed_count += 1
  end
  
  def test_job_statistics
    @test_count += 1
    puts "\nTest: Job statistics"
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "Jobs failed: 50", "Should show failed jobs")
    @helper.assert_includes(output[:stdout], "Jobs enqueued: 15", "Should show enqueued jobs")
    @helper.assert_includes(output[:stdout], "Jobs scheduled: 5", "Should show scheduled jobs")
    @helper.assert_includes(output[:stdout], "Jobs retrying: 3", "Should show retrying jobs")
    @helper.assert_includes(output[:stdout], "Jobs dead: 2", "Should show dead jobs")
    
    @passed_count += 1
  end
  
  def test_worker_performance
    @test_count += 1
    puts "\nTest: Worker performance monitoring"
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "default - ProjectImportWorker", "Should show current job")
    @helper.assert_includes(output[:stdout], "Current jobs:", "Should show current jobs section")
    
    @passed_count += 1
  end
  
  def test_failed_jobs_analysis
    @test_count += 1
    puts "\nTest: Failed jobs analysis"
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "Failed jobs: 1", "Should show failed jobs count")
    @helper.assert_includes(output[:stdout], "StandardError: 1", "Should show error types")
    
    @passed_count += 1
  end
  
  def test_failure_rate_calculation
    @test_count += 1
    puts "\nTest: Failure rate calculation"
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "Failure rate: 5.0%", "Should calculate failure rate correctly")
    
    @passed_count += 1
  end
  
  def test_authentication_required
    @test_count += 1
    puts "\nTest: Authentication required"
    
    @helper.add_mock_response('/api/v4/admin/sidekiq/health', status: 401, body: 'Unauthorized')
    
    stats = GitLabSidekiqStats.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "✗ Failed (HTTP 401)", "Should show authentication error")
    
    @passed_count += 1
  end
  
  def test_network_error_handling
    @test_count += 1
    puts "\nTest: Network error handling"
    
    stats = GitLabSidekiqStats.new("http://nonexistent.local:9999", 'fake-token')
    output = @helper.capture_output { stats.run }
    
    @helper.assert_includes(output[:stdout], "✗ Error:", "Should handle network errors gracefully")
    
    @passed_count += 1
  end
end

if __FILE__ == $0
  test_suite = TestGitLabSidekiqStats.new
  success = test_suite.run_tests
  exit(success ? 0 : 1)
end