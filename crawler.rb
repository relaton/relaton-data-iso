# frozen_string_literal: true

require "relaton/iso/data_fetcher"

# The reusable crawler workflow forwards inputs as
#   ruby crawler.rb <args> <secrets.args>
# so ARGV looks like ["iso-open-data-all"?, "<token>"?]. Pick out the source
# mode (if the dispatch passed one) and treat the remaining arg as the token.
source = ARGV.find { |a| a.start_with?("iso-open-data") }
token  = (ARGV - [source].compact).last
ENV["GITHUB_TOKEN"] = token if token

# DataFetcher decides whether to refresh based on the upstream `Last-Modified`
# header; wiping `data/` here would race the short-circuit and leave an empty
# tree. Pass `"iso-open-data-all"` (or remove `last_modified.txt`) to force a
# full rebuild.
Relaton::Iso::DataFetcher.fetch(source)
