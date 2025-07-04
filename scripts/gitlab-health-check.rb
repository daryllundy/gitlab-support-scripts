#!/usr/bin/env ruby

# GitLab Health Check Script
# Checks various GitLab components and reports their status

require 'net/http'
require 'json'

class GitLabHealthCheck
  def initialize(gitlab_url)
    @gitlab_url = gitlab_url
  end

  def run
    puts "Checking GitLab health at #{@gitlab_url}..."
    
    check_readiness
    check_liveness
    check_version
    check_database_status
    puts "\nHealth check completed."
  end

  private

  def check_readiness
    print "Readiness check... "
    begin
      uri = URI("#{@gitlab_url}/-/readiness")
      response = Net::HTTP.get_response(uri)
      if response.code == '200'
        puts "✓ OK"
      else
        puts "✗ Failed (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def check_liveness
    print "Liveness check... "
    begin
      uri = URI("#{@gitlab_url}/-/liveness")
      response = Net::HTTP.get_response(uri)
      if response.code == '200'
        puts "✓ OK"
      else
        puts "✗ Failed (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def check_version
    print "Version check... "
    begin
      uri = URI("#{@gitlab_url}/api/v4/version")
      response = Net::HTTP.get_response(uri)
      if response.code == '200'
        version_data = JSON.parse(response.body)
        puts "✓ GitLab #{version_data['version']}"
      else
        puts "✗ Failed (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end

  def check_database_status
    print "Database connectivity... "
    begin
      uri = URI("#{@gitlab_url}/-/health")
      response = Net::HTTP.get_response(uri)
      if response.code == '200'
        puts "✓ OK"
      else
        puts "✗ Failed (HTTP #{response.code})"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end
  end
end

if __FILE__ == $0
  checker = GitLabHealthCheck.new(ARGV[0] || 'http://localhost')
  checker.run
end
