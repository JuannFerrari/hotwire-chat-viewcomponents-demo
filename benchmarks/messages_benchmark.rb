# frozen_string_literal: true

# Run with: `RAILS_ENV=production bin/rails runner benchmarks/messages_benchmark.rb`

require "benchmark/ips"
require_relative "../config/environment"

# Make sure logging doesn't clutter output
Rails.logger.silence do
  ActiveRecord::Base.transaction do
    # Create a room
    room = Room.create!(name: "Benchmark Room")

    # Generate dummy messages
    NUM_MESSAGES = 100
    messages = Array.new(NUM_MESSAGES) do |i|
      Message.create!(
        content: "Message ##{i + 1} — Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        room: room
      )
    end

    # Controller to provide view context
    class BenchmarksController < ActionController::Base; end
    BenchmarksController.view_paths = ActionController::Base.view_paths
    controller_view = BenchmarksController.new.view_context

    puts "Running benchmark on #{messages.size} messages..."

    Benchmark.ips do |x|
      x.time = 10
      x.warmup = 2

      x.report("partial") do
        messages.each do |message|
          controller_view.render(
            partial: "messages/message",
            locals: { message: message }
          )
        end
      end

      x.report("component") do
        messages.each do |message|
          controller_view.render(
            MessageComponent.new(message: message)
          )
        end
      end

      x.compare!
    end

    # Rollback all DB changes
    raise ActiveRecord::Rollback
  end
end
