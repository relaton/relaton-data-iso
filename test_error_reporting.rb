# frozen_string_literal: true

require "relaton/iso/data_fetcher"

# Add log_error (needed until the gem is released with this method).
module Relaton
  module Iso
    class DataFetcher < Core::DataFetcher
      def log_error(msg)
        Util.error msg
      end
    end
  end
end

df = Relaton::Iso::DataFetcher.new("tmp_test_output", "yaml")

# Simulate a failed fetch: explicitly set error keys to true.
# In a real fetch, @errors[:key] &&= condition is called for each field.
# Hash.new(true) only stores keys when explicitly assigned.
errors = df.instance_variable_get(:@errors)
errors[:id] = true           # never parsed (error)
errors[:title] = true        # never parsed (error)
errors[:abstract] = true     # never parsed (error)
errors[:date_pub] = true     # never parsed (error)
errors[:date_corr] = true    # never parsed (error)
errors[:edition] = false     # simulated success — no error
errors[:stage] = true        # never parsed (error)
errors[:relation] = true     # never parsed (error)
errors[:ics] = true          # never parsed (error)

puts "Error keys that will be reported:"
puts errors.select { |_, v| v }.keys.map { |k| "  - #{k}" }.join("\n")
puts ""
channel = df.send(:gh_issue_channel)
puts "gh_issue_channel: #{channel.inspect}"
puts "GITHUB_REPOSITORY: #{ENV['GITHUB_REPOSITORY']}"
puts "GITHUB_TOKEN set: #{!ENV['GITHUB_TOKEN'].nil?}"
puts "GITHUB_TOKEN length: #{ENV['GITHUB_TOKEN']&.length}"
puts ""
puts "Calling report_errors..."
df.report_errors
puts "Done."
