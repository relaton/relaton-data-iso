# frozen_string_literal: true

# Smoke-test pubid before the crawl touches `data/`.
#
# The fetcher does a full replace: it wipes `data/` and the v2 index, then
# writes back whatever it can parse. If pubid itself is broken (issue #42: a
# missing parsanol made every parse raise), each id is "unparseable", the index
# comes out empty, the data loses its parsed docids, and the crawler workflow
# commits that and saves `last_modified.txt` so the next run skips the repair.
# Parse a few known ids first and abort the run if any of them fails.
module PubidCheck
  SAMPLES = [
    "ISO 1:2002",
    "ISO/IEC 27001:2022",
    "ISO 9001:2015/Amd 1:2024",
  ].freeze

  module_function

  def verify!(samples = SAMPLES)
    samples.each do |id|
      parsed = ::Pubid::Iso::Identifier.parse(id).to_s
      fail!(id, "got `#{parsed}`") unless parsed == id
    rescue StandardError => e
      fail!(id, "#{e.class}: #{e.message}")
    end
  end

  def fail!(id, reason)
    abort "pubid cannot parse `#{id}` (#{reason}); " \
          "aborting before the crawl overwrites data/ and the indexes"
  end
end
