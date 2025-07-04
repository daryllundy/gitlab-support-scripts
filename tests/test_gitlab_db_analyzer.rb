#!/usr/bin/env ruby

# Test suite for gitlab-db-analyzer.rb

require_relative 'test_helper'
require_relative '../scripts/gitlab-db-analyzer'

class TestGitLabDbAnalyzer
  def initialize
    @helper = TestHelper.new
    @test_count = 0
    @passed_count = 0
  end
  
  def run_tests
    puts "Running GitLab Database Analyzer tests..."
    puts "=" * 40
    
    setup_mock_server
    
    begin
      test_successful_db_analysis
      test_slow_queries_analysis
      test_connection_pool_check
      test_table_sizes_analysis
      test_authentication_required
      test_empty_slow_queries
      test_network_error_handling
      
      puts "\n" + "=" * 40
      puts "Database Analyzer Tests: #{@passed_count}/#{@test_count} passed"
      return @passed_count == @test_count
    ensure
      @helper.stop_mock_server
    end
  end
  
  private
  
  def setup_mock_server
    @helper.start_mock_server
    
    # Add health check endpoint
    @helper.add_mock_response('/-/health', status: 200, body: '{"status":"ok"}')
    
    # Add database analyzer endpoints
    MockGitLabResponses.db_analyzer_responses.each do |path, response|
      @helper.add_mock_response(path, **response)
    end
  end
  
  def test_successful_db_analysis
    @test_count += 1
    puts "\nTest: Successful database analysis"
    
    analyzer = GitLabDbAnalyzer.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { analyzer.run }
    
    @helper.assert_includes(output[:stdout], "✓ Connected", "Database health check should pass")
    @helper.assert_includes(output[:stdout], "Found 1 slow queries", "Should detect slow queries")
    @helper.assert_includes(output[:stdout], "Active: 5/20", "Should show connection pool stats")
    @helper.assert_includes(output[:stdout], "Found 1 tables", "Should show table count")
    @helper.assert_includes(output[:stdout], "Database analysis completed", "Should complete successfully")
    
    @passed_count += 1
  end
  
  def test_slow_queries_analysis
    @test_count += 1
    puts "\nTest: Slow queries analysis"
    
    analyzer = GitLabDbAnalyzer.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { analyzer.run }
    
    @helper.assert_includes(output[:stdout], "Duration: 1500ms", "Should show query duration")
    @helper.assert_includes(output[:stdout], "SELECT * FROM projects", "Should show query snippet")
    
    @passed_count += 1
  end
  
  def test_connection_pool_check
    @test_count += 1
    puts "\nTest: Connection pool check"
    
    analyzer = GitLabDbAnalyzer.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { analyzer.run }
    
    @helper.assert_includes(output[:stdout], "Active: 5/20", "Should show active connections")
    @helper.assert_includes(output[:stdout], "Waiting: 0", "Should show waiting connections")
    
    @passed_count += 1
  end
  
  def test_table_sizes_analysis
    @test_count += 1
    puts "\nTest: Table sizes analysis"
    
    analyzer = GitLabDbAnalyzer.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { analyzer.run }
    
    @helper.assert_includes(output[:stdout], "projects: 1.0MB", "Should show table size")
    @helper.assert_includes(output[:stdout], "Largest tables:", "Should show largest tables section")
    
    @passed_count += 1
  end
  
  def test_authentication_required
    @test_count += 1
    puts "\nTest: Authentication required"
    
    @helper.add_mock_response('/api/v4/admin/database/slow_queries', status: 401, body: 'Unauthorized')
    
    analyzer = GitLabDbAnalyzer.new(@helper.mock_gitlab_url)
    output = @helper.capture_output { analyzer.run }
    
    @helper.assert_includes(output[:stdout], "✗ Failed to retrieve (HTTP 401)", "Should show authentication error")
    
    @passed_count += 1
  end
  
  def test_empty_slow_queries
    @test_count += 1
    puts "\nTest: Empty slow queries"
    
    @helper.add_mock_response('/api/v4/admin/database/slow_queries', status: 200, body: '[]')
    
    analyzer = GitLabDbAnalyzer.new(@helper.mock_gitlab_url, 'fake-token')
    output = @helper.capture_output { analyzer.run }
    
    @helper.assert_includes(output[:stdout], "✓ No slow queries detected", "Should handle empty slow queries")
    
    @passed_count += 1
  end
  
  def test_network_error_handling
    @test_count += 1
    puts "\nTest: Network error handling"
    
    analyzer = GitLabDbAnalyzer.new("http://nonexistent.local:9999", 'fake-token')
    output = @helper.capture_output { analyzer.run }
    
    @helper.assert_includes(output[:stdout], "✗ Error:", "Should handle network errors gracefully")
    
    @passed_count += 1
  end
end

if __FILE__ == $0
  test_suite = TestGitLabDbAnalyzer.new
  success = test_suite.run_tests
  exit(success ? 0 : 1)
end