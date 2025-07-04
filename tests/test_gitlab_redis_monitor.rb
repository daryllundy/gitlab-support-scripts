#!/usr/bin/env ruby

# Test suite for gitlab-redis-monitor.rb

require_relative 'test_helper'
require_relative '../scripts/gitlab-redis-monitor'

class TestGitLabRedisMonitor
  def initialize
    @helper = TestHelper.new
    @test_count = 0
    @passed_count = 0
  end
  
  def run_tests
    puts "Running GitLab Redis Monitor tests..."
    puts "=" * 40
    
    setup_mock_server
    
    begin
      test_successful_redis_monitoring
      test_redis_health_check
      test_memory_usage_monitoring
      test_connection_statistics
      test_key_pattern_analysis
      test_authentication_required
      test_hit_rate_calculation
      test_network_error_handling
      
      puts "\n" + "=" * 40
      puts "Redis Monitor Tests: #{@passed_count}/#{@test_count} passed"
      return @passed_count == @test_count
    ensure
      @helper.stop_mock_server
    end
  end
  
  private
  
  def setup_mock_server
    @helper.start_mock_server
    
    # Add Redis monitor endpoints
    MockGitLabResponses.redis_monitor_responses.each do |path, response|
      @helper.add_mock_response(path, **response)
    end
  end
  
  def test_successful_redis_monitoring
    @test_count += 1
    puts "\nTest: Successful Redis monitoring"
    
    monitor = GitLabRedisMonitor.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "✓ Connected (connected)", "Redis health check should pass")
    @helper.assert_includes(output[:stdout], "✓ Used: 1.0MB", "Should show memory usage")
    @helper.assert_includes(output[:stdout], "✓ Connected clients: 10", "Should show connection stats")
    @helper.assert_includes(output[:stdout], "✓ Total keys: 100", "Should show key analysis")
    @helper.assert_includes(output[:stdout], "Redis monitoring completed", "Should complete successfully")
    
    @passed_count += 1
  end
  
  def test_redis_health_check
    @test_count += 1
    puts "\nTest: Redis health check"
    
    monitor = GitLabRedisMonitor.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "Version: 6.2.0", "Should show Redis version")
    @helper.assert_includes(output[:stdout], "Uptime: 3600s", "Should show uptime")
    
    @passed_count += 1
  end
  
  def test_memory_usage_monitoring
    @test_count += 1
    puts "\nTest: Memory usage monitoring"
    
    monitor = GitLabRedisMonitor.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "Peak: 2.0MB", "Should show peak memory")
    @helper.assert_includes(output[:stdout], "Fragmentation ratio: 1.1", "Should show fragmentation ratio")
    @helper.assert_includes(output[:stdout], "Keys: 100", "Should show key count")
    
    @passed_count += 1
  end
  
  def test_connection_statistics
    @test_count += 1
    puts "\nTest: Connection statistics"
    
    monitor = GitLabRedisMonitor.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "Total connections: 1000", "Should show total connections")
    @helper.assert_includes(output[:stdout], "Commands processed: 5000", "Should show commands processed")
    @helper.assert_includes(output[:stdout], "Keyspace hits: 800", "Should show keyspace hits")
    @helper.assert_includes(output[:stdout], "Keyspace misses: 200", "Should show keyspace misses")
    
    @passed_count += 1
  end
  
  def test_key_pattern_analysis
    @test_count += 1
    puts "\nTest: Key pattern analysis"
    
    monitor = GitLabRedisMonitor.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "cache:*: 50", "Should show cache key pattern")
    @helper.assert_includes(output[:stdout], "session:*: 30", "Should show session key pattern")
    @helper.assert_includes(output[:stdout], "Expired keys: 10", "Should show expired keys")
    
    @passed_count += 1
  end
  
  def test_authentication_required
    @test_count += 1
    puts "\nTest: Authentication required"
    
    @helper.add_mock_response('/api/v4/admin/redis/health', status: 401, body: 'Unauthorized')
    
    monitor = GitLabRedisMonitor.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "✗ Failed (HTTP 401)", "Should show authentication error")
    
    @passed_count += 1
  end
  
  def test_hit_rate_calculation
    @test_count += 1
    puts "\nTest: Hit rate calculation"
    
    monitor = GitLabRedisMonitor.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "Hit rate: 80.0%", "Should calculate hit rate correctly")
    
    @passed_count += 1
  end
  
  def test_network_error_handling
    @test_count += 1
    puts "\nTest: Network error handling"
    
    monitor = GitLabRedisMonitor.new("http://nonexistent.local:9999", 'fake-token')
    output = @helper.capture_output { monitor.run }
    
    @helper.assert_includes(output[:stdout], "✗ Error:", "Should handle network errors gracefully")
    
    @passed_count += 1
  end
end

if __FILE__ == $0
  test_suite = TestGitLabRedisMonitor.new
  success = test_suite.run_tests
  exit(success ? 0 : 1)
end