# frozen_string_literal: true

require "relaton/iso/data_fetcher"
require "rbconfig"
require "bundler"

# The reusable crawler workflow forwards inputs as
#   ruby crawler.rb <args> <secrets.args>
# so ARGV looks like ["iso-open-data-all"?, "<token>"?]. Pick out the source
# mode (if the dispatch passed one) and treat the remaining arg as the token.
source = ARGV.find { |a| a.start_with?("iso-open-data") }
token  = (ARGV - [source].compact).last
ENV["GITHUB_TOKEN"] = token if token

# Fetch into `data/` and rebuild `index-v2` (parsed with pubid v2).
#
# The feed has no delta API, so DataFetcher either skips entirely (when the
# feed's `Last-Modified` is unchanged) or does a full replace — wiping `data/`
# and the v2 index in step, after its short-circuit check, so nothing stale
# lingers. It returns true only when it actually rebuilt. `iso-open-data-all`
# forces a rebuild by ignoring the short-circuit.
rebuilt = Relaton::Iso::DataFetcher.fetch(source)

# Persist the `Last-Modified` short-circuit state. The reusable crawler workflow
# only auto-commits `data/*` and `index*.yaml`; other files must be staged
# explicitly (as the sibling data repos do for their index files), or
# `last_modified.txt` never survives between CI runs and the short-circuit can
# never trigger.
system("git", "add", "last_modified.txt") if File.exist?("last_modified.txt")

# Rebuild `index-v1` (the released gem line, identifiers parsed with pubid v1)
# only when the data actually changed. pubid v1 and the pubid v2 loaded above
# both define `Pubid::Iso::Identifier` and cannot coexist in one process, so run
# it in a separate process with its own bundle. It rebuilds from scratch, so it
# stays in sync with the full replace above.
if rebuilt
  Bundler.with_unbundled_env do
    ok = system(RbConfig.ruby, File.join(__dir__, "build_index_v1.rb"))
    abort "build_index_v1.rb failed" unless ok
  end
end
