#!/usr/bin/env ruby

# GitLab Database Analyzer
# Analyzes database performance and query patterns

require 'net/http'
require 'json'
require 'uri'

class GitLabDbAnalyzer
  def initialize(gitlab_url, access_token = nil)
    @gitlab_url = gitlab_url
    @access_token = access_token
    @headers = {}
    @headers['PRIVATE-TOKEN'] = @access_token if @access_token
  end

  def run
    puts "Analyzing GitLab database performance at #{@gitlab_url}..."
    
    check_database_health
    analyze_slow_queries
    check_connection_pool
    analyze_table_sizes
    puts "\nDatabase analysis completed."
  end

  private

  def check_database_health
    puts "\n=== Database Health Check ==="
    print "Database connectivity... "
    begin
      uri = URI("#{@gitlab_url}/-/health")
      response = get_response(uri)
      if response.code == '200'
        puts "✓ Connected"
      else
        puts "✗ Failed (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def analyze_slow_queries
    puts "\n=== Slow Query Analysis ==="
    print "Checking for slow queries... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/database/slow_queries")
      response = get_response(uri)
      if response.code == '200'
        queries = JSON.parse(response.body)
        if queries.empty?
          puts "✓ No slow queries detected"
        else
          puts "⚠ Found #{queries.length} slow queries"
          queries.first(5).each_with_index do |query, index|
            puts "  #{index + 1}. Duration: #{query['duration']}ms - #{query['query'][0..50]}..."
          end
        end
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def check_connection_pool
    puts "\n=== Connection Pool Status ==="
    print "Checking connection pool... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/database/connection_pool")
      response = get_response(uri)
      if response.code == '200'
        pool_data = JSON.parse(response.body)
        puts "✓ Active: #{pool_data['active']}/#{pool_data['size']}"
        puts "  Waiting: #{pool_data['waiting']}"
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def analyze_table_sizes
    puts "\n=== Table Size Analysis ==="
    print "Analyzing table sizes... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/database/table_sizes")
      response = get_response(uri)
      if response.code == '200'
        tables = JSON.parse(response.body)
        puts "✓ Found #{tables.length} tables"
        puts "  Largest tables:"
        tables.first(5).each do |table|
          size_mb = (table['size_bytes'].to_f / 1024 / 1024).round(2)
          puts "    #{table['table_name']}: #{size_mb}MB"
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
  
  analyzer = GitLabDbAnalyzer.new(ARGV[0], ARGV[1])
  analyzer.run
end