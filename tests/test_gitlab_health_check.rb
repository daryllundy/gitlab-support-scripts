#!/usr/bin/env ruby

# Test suite for gitlab-health-check.rb

require_relative 'test_helper'
require_relative '../scripts/gitlab-health-check'

class TestGitLabHealthCheck
  def initialize
    @helper = TestHelper.new
    @test_count = 0
    @passed_count = 0
  end
  
  def run_tests
    puts "Running GitLab Health Check tests..."
    puts "=" * 40
    
    setup_mock_server
    
    begin
      test_successful_health_check
      test_failed_readiness_check
      test_failed_liveness_check
      test_version_check_failure
      test_database_check_failure
      test_network_error_handling
      test_invalid_json_response
      
      puts "\n" + "=" * 40
      puts "Health Check Tests: #{@passed_count}/#{@test_count} passed"
      return @passed_count == @test_count
    ensure
      @helper.stop_mock_server
    end
  end
  
  private
  
  def setup_mock_server
    @helper.start_mock_server
    MockGitLabResponses.health_check_responses.each do |path, response|
      @helper.add_mock_response(path, **response)
    end
  end
  
  def test_successful_health_check
    @test_count += 1
    puts "\nTest: Successful health check"
    
    checker = GitLabHealthCheck.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { checker.run }
    
    @helper.assert_includes(output[:stdout], "✓ OK", "Readiness check should pass")
    @helper.assert_includes(output[:stdout], "✓ GitLab 14.6.0", "Version should be displayed")
    @helper.assert_includes(output[:stdout], "Health check completed", "Should complete successfully")
    
    @passed_count += 1
  end
  
  def test_failed_readiness_check
    @test_count += 1
    puts "\nTest: Failed readiness check"
    
    @helper.add_mock_response('/-/readiness', status: 503, body: 'Service Unavailable')
    
    checker = GitLabHealthCheck.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { checker.run }
    
    @helper.assert_includes(output[:stdout], "✗ Failed (HTTP 503)", "Should show failed readiness")
    
    @passed_count += 1
  end
  
  def test_failed_liveness_check
    @test_count += 1
    puts "\nTest: Failed liveness check"
    
    @helper.add_mock_response('/-/liveness', status: 500, body: 'Internal Server Error')
    
    checker = GitLabHealthCheck.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { checker.run }
    
    @helper.assert_includes(output[:stdout], "✗ Failed (HTTP 500)", "Should show failed liveness")
    
    @passed_count += 1
  end
  
  def test_version_check_failure
    @test_count += 1
    puts "\nTest: Version check failure"
    
    @helper.add_mock_response('/api/v4/version', status: 404, body: 'Not Found')
    
    checker = GitLabHealthCheck.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { checker.run }
    
    @helper.assert_includes(output[:stdout], "✗ Failed (HTTP 404)", "Should show failed version check")
    
    @passed_count += 1
  end
  
  def test_database_check_failure
    @test_count += 1
    puts "\nTest: Database check failure"
    
    @helper.add_mock_response('/-/health', status: 503, body: 'Database connection failed')
    
    checker = GitLabHealthCheck.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { checker.run }
    
    @helper.assert_includes(output[:stdout], "✗ Failed (HTTP 503)", "Should show failed database check")
    
    @passed_count += 1
  end
  
  def test_network_error_handling
    @test_count += 1
    puts "\nTest: Network error handling"
    
    checker = GitLabHealthCheck.new("http://nonexistent.local:9999")
    output = @helper.capture_output { checker.run }
    
    @helper.assert_includes(output[:stdout], "✗ Error:", "Should handle network errors gracefully")
    
    @passed_count += 1
  end
  
  def test_invalid_json_response
    @test_count += 1
    puts "\nTest: Invalid JSON response handling"
    
    @helper.add_mock_response('/api/v4/version', status: 200, body: 'invalid json')
    
    checker = GitLabHealthCheck.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { checker.run }
    
    @helper.assert_includes(output[:stdout], "✗ Error:", "Should handle invalid JSON gracefully")
    
    @passed_count += 1
  end
end

if __FILE__ == $0
  test_suite = TestGitLabHealthCheck.new
  success = test_suite.run_tests
  exit(success ? 0 : 1)
end