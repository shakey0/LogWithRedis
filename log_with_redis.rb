#!/usr/bin/env ruby

require 'redis'
require 'json'
require 'colorize'
require 'pygments'

class LogWithRedis
  COLORS = {
    'yellow' => :light_yellow,
    'blue' => :light_blue,
    'red' => :light_red,
    'green' => :light_green,
    'cyan' => :light_cyan,
    'magenta' => :light_magenta
  }

  def initialize
    @redis = Redis.new
    
    # Ask for base key
    print "Enter the base key to monitor (default: lwr): "
    input = gets.chomp
    @base_key = input.empty? ? 'lwr' : input
    
    puts "Connected to Redis, monitoring list '#{@base_key}'..."
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

  def process_logs
    # Check only the base key
    while (log_entry = @redis.rpop(@base_key))
      # Extract color from the entry if present (---color format)
      color = nil
      content = log_entry
      
      # Check if the entry ends with ---color
      COLORS.keys.each do |color_name|
        if log_entry.end_with?("---#{color_name}")
          color = COLORS[color_name]
          # Remove the color tag from the content
          content = log_entry.gsub(/---#{color_name}$/, '')
          break
        end
      end
      
      # Parse the entry
      parsed_entry = parse_entry(content)
      
      # Print empty line before each log entry
      puts

      # Print the entry
      if parsed_entry.is_a?(Hash) || parsed_entry.is_a?(Array)
        # For JSON objects, just print the JSON without special coloring
        output = JSON.pretty_generate(parsed_entry)
        puts Pygments.highlight(output, lexer: 'json', formatter: 'terminal256', options: { style: 'monokai' })
      else
        # For strings, apply the color if one was specified
        if color
          puts parsed_entry.to_s.colorize(color)
        else
          puts parsed_entry.to_s
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
