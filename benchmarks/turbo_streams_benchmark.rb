# frozen_string_literal: true
# Run with: `RAILS_ENV=production bin/rails runner benchmarks/turbo_streams_benchmark.rb`

require "benchmark/ips"
require_relative "../config/environment"

NUM_MESSAGES = 100

# Controller to provide view context
class BenchmarksController < ActionController::Base; end
BenchmarksController.view_paths = ActionController::Base.view_paths
view = BenchmarksController.new.view_context

puts "Preparing Turbo Stream benchmark with #{NUM_MESSAGES} messages..."
STDOUT.flush

# Wrap everything in a transaction to keep DB clean
ActiveRecord::Base.transaction do
  # Create a room
  room = Room.first || Room.create!(name: "Benchmark Room")

  # Create dummy messages
  messages = Array.new(NUM_MESSAGES) do |i|
    Message.create!(
      content: "Message ##{i + 1} — Lorem ipsum dolor sit amet.",
      room: room
    )
  end

  puts "Running Turbo Stream benchmark..."
  STDOUT.flush

  Benchmark.ips do |x|
    x.time = 10
    x.warmup = 2

    x.report("turbo_stream partial") do
      messages.each do |message|
        html = view.turbo_stream.append(
          "messages",
          partial: "messages/message",
          locals: { message: message }
        )
        html.to_s
      end
    end

    x.report("turbo_stream component") do
      messages.each do |message|
        html = view.turbo_stream.append(
          "messages",
          MessageComponent.new(message: message)
        )
        html.to_s
      end
    end

    x.compare!
  end

  # Rollback DB to keep it clean
  raise ActiveRecord::Rollback
end
