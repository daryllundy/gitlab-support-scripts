#!/usr/bin/env ruby

# GitLab Redis Monitor
# Monitors Redis performance and connection status

require 'net/http'
require 'json'
require 'uri'

class GitLabRedisMonitor
  def initialize(gitlab_url, access_token = nil)
    @gitlab_url = gitlab_url
    @access_token = access_token
    @headers = {}
    @headers['PRIVATE-TOKEN'] = @access_token if @access_token
  end

  def run
    puts "Monitoring GitLab Redis at #{@gitlab_url}..."
    
    check_redis_health
    monitor_memory_usage
    check_connection_stats
    analyze_key_patterns
    puts "\nRedis monitoring completed."
  end

  private

  def check_redis_health
    puts "\n=== Redis Health Check ==="
    print "Redis connectivity... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/redis/health")
      response = get_response(uri)
      if response.code == '200'
        health_data = JSON.parse(response.body)
        puts "✓ Connected (#{health_data['status']})"
        puts "  Version: #{health_data['version']}"
        puts "  Uptime: #{health_data['uptime_in_seconds']}s"
      else
        puts "✗ Failed (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def monitor_memory_usage
    puts "\n=== Memory Usage ==="
    print "Checking memory usage... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/redis/memory")
      response = get_response(uri)
      if response.code == '200'
        memory_data = JSON.parse(response.body)
        used_mb = (memory_data['used_memory'].to_f / 1024 / 1024).round(2)
        peak_mb = (memory_data['used_memory_peak'].to_f / 1024 / 1024).round(2)
        puts "✓ Used: #{used_mb}MB (Peak: #{peak_mb}MB)"
        puts "  Fragmentation ratio: #{memory_data['mem_fragmentation_ratio']}"
        puts "  Keys: #{memory_data['db0']['keys']}" if memory_data['db0']
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def check_connection_stats
    puts "\n=== Connection Statistics ==="
    print "Checking connections... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/redis/stats")
      response = get_response(uri)
      if response.code == '200'
        stats_data = JSON.parse(response.body)
        puts "✓ Connected clients: #{stats_data['connected_clients']}"
        puts "  Total connections: #{stats_data['total_connections_received']}"
        puts "  Commands processed: #{stats_data['total_commands_processed']}"
        puts "  Keyspace hits: #{stats_data['keyspace_hits']}"
        puts "  Keyspace misses: #{stats_data['keyspace_misses']}"
        
        if stats_data['keyspace_hits'].to_i > 0
          hit_rate = (stats_data['keyspace_hits'].to_f / (stats_data['keyspace_hits'].to_i + stats_data['keyspace_misses'].to_i) * 100).round(2)
          puts "  Hit rate: #{hit_rate}%"
        end
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def analyze_key_patterns
    puts "\n=== Key Pattern Analysis ==="
    print "Analyzing key patterns... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/redis/keys")
      response = get_response(uri)
      if response.code == '200'
        keys_data = JSON.parse(response.body)
        puts "✓ Total keys: #{keys_data['total_keys']}"
        
        if keys_data['patterns']
          puts "  Key patterns:"
          keys_data['patterns'].each do |pattern, count|
            puts "    #{pattern}: #{count}"
          end
        end
        
        if keys_data['expired_keys']
          puts "  Expired keys: #{keys_data['expired_keys']}"
        end
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def get_response(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Get.new(uri)
    @headers.each { |key, value| request[key] = value }
    http.request(request)
  end
end

if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: #{$0} <gitlab_url> [access_token]"
    puts "Example: #{$0} https://gitlab.example.com glpat-xxxxxxxxxxxxxxxxxxxx"
    exit 1
  end
  
  monitor = GitLabRedisMonitor.new(ARGV[0], ARGV[1])
  monitor.run
end