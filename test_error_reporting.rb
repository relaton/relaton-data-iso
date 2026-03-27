# frozen_string_literal: true

require "relaton/iso/data_fetcher"

# Override gh_issue_channel to target this repo and add log_error
# (needed until the gem is released with these methods).
module Relaton
  module Iso
    class DataFetcher < Core::DataFetcher
      def gh_issue_channel
        repo = ENV.fetch("GITHUB_REPOSITORY", "relaton/relaton-data-iso")
        [repo, "Test: Error fetching ISO documents"]
      end

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
puts "Calling repot_errors..."
df.repot_errors
puts "Done."
