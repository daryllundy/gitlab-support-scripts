#!/usr/bin/env ruby

# Test Helper for GitLab Support Scripts
# Provides common utilities and mock functionality for testing

require 'net/http'
require 'json'
require 'uri'
require 'webrick'
require 'thread'

class TestHelper
  attr_accessor :mock_server, :mock_port, :mock_responses
  
  def initialize
    @mock_port = 8080
    @mock_responses = {}
    @mock_server = nil
    @server_thread = nil
  end
  
  def start_mock_server
    @mock_server = WEBrick::HTTPServer.new(
      Port: @mock_port,
      Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
      AccessLog: []
    )
    
    # Add mock endpoints
    @mock_server.mount_proc('/') do |req, res|
      path = req.path
      method = req.request_method
      
      if @mock_responses.key?(path)
        response_data = @mock_responses[path]
        res.status = response_data[:status] || 200
        res['Content-Type'] = response_data[:content_type] || 'application/json'
        res.body = response_data[:body] || '{}'
      else
        res.status = 404
        res.body = 'Not Found'
      end
    end
    
    @server_thread = Thread.new { @mock_server.start }
    sleep 0.1  # Give server time to start
  end
  
  def stop_mock_server
    @mock_server.shutdown if @mock_server
    @server_thread.join if @server_thread
  end
  
  def add_mock_response(path, status: 200, body: '{}', content_type: 'application/json')
    @mock_responses[path] = {
      status: status,
      body: body,
      content_type: content_type
    }
  end
  
  def mock_gitlab_url
    "http://localhost:#{@mock_port}"
  end
  
  def create_temp_backup_dir
    require 'tmpdir'
    require 'fileutils'
    
    temp_dir = Dir.mktmpdir('gitlab_backup_test')
    
    # Create mock backup files
    backup_tar = File.join(temp_dir, '1640995200_2021_12_31_14.6.0_gitlab_backup.tar')
    File.write(backup_tar, 'mock backup content')
    
    # Create mock configuration files
    File.write(File.join(temp_dir, 'gitlab.rb'), 'external_url "https://gitlab.example.com"')
    File.write(File.join(temp_dir, 'gitlab-secrets.json'), '{"db_key_base": "secret"}')
    
    temp_dir
  end
  
  def cleanup_temp_dir(dir)
    require 'fileutils'
    FileUtils.remove_entry(dir) if dir && Dir.exist?(dir)
  end
  
  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    
    begin
      yield
      { stdout: $stdout.string, stderr: $stderr.string }
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end
  
  def assert(condition, message = "Assertion failed")
    unless condition
      puts "❌ #{message}"
      exit 1
    end
    puts "✓ #{message}"
  end
  
  def assert_equal(expected, actual, message = "Values should be equal")
    unless expected == actual
      puts "❌ #{message}: expected #{expected}, got #{actual}"
      exit 1
    end
    puts "✓ #{message}"
  end
  
  def assert_includes(collection, item, message = "Item should be included")
    unless collection.include?(item)
      puts "❌ #{message}: #{item} not found in collection"
      exit 1
    end
    puts "✓ #{message}"
  end
end

# Mock GitLab API responses
class MockGitLabResponses
  def self.health_check_responses
    {
      '/-/readiness' => { status: 200, body: '{"status":"ok"}' },
      '/-/liveness' => { status: 200, body: '{"status":"ok"}' },
      '/-/health' => { status: 200, body: '{"status":"ok"}' },
      '/api/v4/version' => { 
        status: 200, 
        body: '{"version":"14.6.0","revision":"abc123"}' 
      }
    }
  end
  
  def self.db_analyzer_responses
    {
      '/api/v4/admin/database/slow_queries' => {
        status: 200,
        body: '[{"duration":1500,"query":"SELECT * FROM projects WHERE..."}]'
      },
      '/api/v4/admin/database/connection_pool' => {
        status: 200,
        body: '{"active":5,"size":20,"waiting":0}'
      },
      '/api/v4/admin/database/table_sizes' => {
        status: 200,
        body: '[{"table_name":"projects","size_bytes":1048576}]'
      }
    }
  end
  
  def self.redis_monitor_responses
    {
      '/api/v4/admin/redis/health' => {
        status: 200,
        body: '{"status":"connected","version":"6.2.0","uptime_in_seconds":3600}'
      },
      '/api/v4/admin/redis/memory' => {
        status: 200,
        body: '{"used_memory":1048576,"used_memory_peak":2097152,"mem_fragmentation_ratio":1.1,"db0":{"keys":100}}'
      },
      '/api/v4/admin/redis/stats' => {
        status: 200,
        body: '{"connected_clients":10,"total_connections_received":1000,"total_commands_processed":5000,"keyspace_hits":800,"keyspace_misses":200}'
      },
      '/api/v4/admin/redis/keys' => {
        status: 200,
        body: '{"total_keys":100,"patterns":{"cache:*":50,"session:*":30},"expired_keys":10}'
      }
    }
  end
  
  def self.sidekiq_stats_responses
    {
      '/api/v4/admin/sidekiq/health' => {
        status: 200,
        body: '{"status":"running","processes":2,"busy":5,"queue_latency":0.5}'
      },
      '/api/v4/admin/sidekiq/queues' => {
        status: 200,
        body: '[{"name":"default","size":10},{"name":"mailers","size":5}]'
      },
      '/api/v4/admin/sidekiq/stats' => {
        status: 200,
        body: '{"processed":1000,"failed":50,"enqueued":15,"scheduled":5,"retry":3,"dead":2}'
      },
      '/api/v4/admin/sidekiq/workers' => {
        status: 200,
        body: '[{"queue":"default","class":"ProjectImportWorker","run_at":1640995200}]'
      },
      '/api/v4/admin/sidekiq/failed_jobs' => {
        status: 200,
        body: '[{"error_class":"StandardError","queue":"default"}]'
      }
    }
  end
end