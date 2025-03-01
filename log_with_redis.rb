#!/usr/bin/env ruby

require 'redis'
require 'json'
require 'colorize'

class LogWithRedis
  COLORS = %w[yellow blue red green cyan]

  def initialize
    @redis = Redis.new
    
    # Ask for base key
    print "Enter the base key to monitor (default: lwr): "
    input = gets.chomp
    @base_key = input.empty? ? 'lwr' : input
    
    puts "Connected to Redis, monitoring list '#{@base_key}' and colored variants..."
    puts "Press Ctrl+C to exit"
    puts "--------------------------------------------------"
  end

  def start
    loop do
      process_logs
      sleep 1
    end
  rescue Interrupt
    puts "\nExiting..."
  rescue Redis::CannotConnectError => e
    puts "Error connecting to Redis: #{e.message}".colorize(:red)
    puts "Please make sure Redis is running."
    exit(1)
  end

  private

  def colorize_json(json) # !!!!!!!!!! THIS PART NEEDS FIXING !!!!!!!!!!
    json.gsub(/"(.*?)":/) { |match| match.colorize(:cyan) }  # Keys in cyan
        .gsub(/: "(.*?)"/) { |match| match.colorize(:green) } # Strings in green
        .gsub(/: (\d+)/) { |match| match.colorize(:yellow) }    # Numbers in yellow
        .gsub(/: (true|false)/) { |match| match.colorize(:red) } # Booleans in red
  end

  def process_logs
    # Check all possible keys (base key and all color variants)
    all_keys = [@redis.keys("#{@base_key}"), @redis.keys("#{@base_key}-*")].flatten.compact
    
    all_keys.each do |key|
      # Extract color from key if present
      color = nil
      if key.include?('-')
        base, color_name = key.split('-', 2)
        color = color_name if COLORS.include?(color_name)
      end
      
      # Use RPOP to get items in the order they were added (FIFO)
      while (log_entry = @redis.rpop(key))
        parsed_entry = parse_entry(log_entry)
        
        # Print empty line before each log entry
        puts

        # Print the entry
        if parsed_entry.is_a?(Hash) || parsed_entry.is_a?(Array)
          output = JSON.pretty_generate(parsed_entry)
          if color
            puts output.colorize(color.to_sym)
          else
            puts colorize_json(output)
          end
        else
          if color
            puts parsed_entry.to_s.colorize(color.to_sym)
          else
            puts parsed_entry.to_s
          end
        end
      end
    end
  end

  def parse_entry(entry)
    # Try to parse as JSON
    begin
      parsed = JSON.parse(entry)
      return parsed
    rescue JSON::ParserError
      # Not valid JSON, return as is
      return entry
    end
  end
end

# Start monitoring
LogWithRedis.new.start
