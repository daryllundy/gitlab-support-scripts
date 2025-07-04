#!/usr/bin/env ruby

# GitLab Sidekiq Statistics
# Analyzes Sidekiq queue performance and job statistics

require 'net/http'
require 'json'
require 'uri'

class GitLabSidekiqStats
  def initialize(gitlab_url, access_token = nil)
    @gitlab_url = gitlab_url
    @access_token = access_token
    @headers = {}
    @headers['PRIVATE-TOKEN'] = @access_token if @access_token
  end

  def run
    puts "Analyzing GitLab Sidekiq statistics at #{@gitlab_url}..."
    
    check_sidekiq_health
    analyze_queue_stats
    check_job_statistics
    monitor_worker_performance
    analyze_failed_jobs
    puts "\nSidekiq analysis completed."
  end

  private

  def check_sidekiq_health
    puts "\n=== Sidekiq Health Check ==="
    print "Sidekiq status... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/sidekiq/health")
      response = get_response(uri)
      if response.code == '200'
        health_data = JSON.parse(response.body)
        puts "✓ Running (#{health_data['status']})"
        puts "  Processes: #{health_data['processes']}"
        puts "  Busy workers: #{health_data['busy']}"
        puts "  Queue latency: #{health_data['queue_latency']}s"
      else
        puts "✗ Failed (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def analyze_queue_stats
    puts "\n=== Queue Statistics ==="
    print "Analyzing queues... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/sidekiq/queues")
      response = get_response(uri)
      if response.code == '200'
        queues_data = JSON.parse(response.body)
        puts "✓ Found #{queues_data.length} queues"
        
        total_jobs = queues_data.sum { |q| q['size'].to_i }
        puts "  Total queued jobs: #{total_jobs}"
        
        if queues_data.any?
          puts "  Top queues by size:"
          queues_data.sort_by { |q| -q['size'].to_i }.first(5).each do |queue|
            puts "    #{queue['name']}: #{queue['size']} jobs"
          end
        end
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def check_job_statistics
    puts "\n=== Job Statistics ==="
    print "Checking job stats... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/sidekiq/stats")
      response = get_response(uri)
      if response.code == '200'
        stats_data = JSON.parse(response.body)
        puts "✓ Jobs processed: #{stats_data['processed']}"
        puts "  Jobs failed: #{stats_data['failed']}"
        puts "  Jobs enqueued: #{stats_data['enqueued']}"
        puts "  Jobs scheduled: #{stats_data['scheduled']}"
        puts "  Jobs retrying: #{stats_data['retry']}"
        puts "  Jobs dead: #{stats_data['dead']}"
        
        if stats_data['processed'].to_i > 0
          failure_rate = (stats_data['failed'].to_f / stats_data['processed'].to_f * 100).round(2)
          puts "  Failure rate: #{failure_rate}%"
        end
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def monitor_worker_performance
    puts "\n=== Worker Performance ==="
    print "Monitoring workers... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/sidekiq/workers")
      response = get_response(uri)
      if response.code == '200'
        workers_data = JSON.parse(response.body)
        puts "✓ Active workers: #{workers_data.length}"
        
        if workers_data.any?
          puts "  Current jobs:"
          workers_data.first(5).each_with_index do |worker, index|
            runtime = Time.now.to_i - worker['run_at'].to_i
            puts "    #{index + 1}. #{worker['queue']} - #{worker['class']} (#{runtime}s)"
          end
        end
      else
        puts "✗ Failed to retrieve (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def analyze_failed_jobs
    puts "\n=== Failed Jobs Analysis ==="
    print "Analyzing failed jobs... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/admin/sidekiq/failed_jobs")
      response = get_response(uri)
      if response.code == '200'
        failed_jobs = JSON.parse(response.body)
        puts "✓ Failed jobs: #{failed_jobs.length}"
        
        if failed_jobs.any?
          error_counts = Hash.new(0)
          failed_jobs.each do |job|
            error_counts[job['error_class']] += 1
          end
          
          puts "  Top error types:"
          error_counts.sort_by { |_, count| -count }.first(5).each do |error_class, count|
            puts "    #{error_class}: #{count}"
          end
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
  
  stats = GitLabSidekiqStats.new(ARGV[0], ARGV[1])
  stats.run
end