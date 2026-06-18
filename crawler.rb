# frozen_string_literal: true

require "relaton/iso/data_fetcher"
require "fileutils"
require "rbconfig"
require "bundler"

# The reusable crawler workflow forwards inputs as
#   ruby crawler.rb <args> <secrets.args>
# so ARGV looks like ["iso-open-data-all"?, "<token>"?]. Pick out the source
# mode (if the dispatch passed one) and treat the remaining arg as the token.
source = ARGV.find { |a| a.start_with?("iso-open-data") }
token  = (ARGV - [source].compact).last
ENV["GITHUB_TOKEN"] = token if token

full_refresh = source == "iso-open-data-all"

# Full rebuild: wipe the curated tree and both indexes up front so records that
# have left the feed (e.g. a DIS that became an FDIS) don't survive as stale
# YAML files or dangling index entries.
#
# This is done here, before the fetch, rather than inside DataFetcher, and only
# for `iso-open-data-all`: that mode always runs past DataFetcher's
# `Last-Modified` short-circuit, so wiping cannot strand an empty tree. Wiping
# for the default incremental mode would race the short-circuit and leave an
# empty tree. Incremental runs only add/update files (never delete), so nothing
# dangles there.
if full_refresh
  FileUtils.rm_rf("data")
  FileUtils.rm_f(Dir["index-v*.yaml"])
end

# Fetch documents into `data/` and (re)build `index-v2` (parsed with pubid v2).
Relaton::Iso::DataFetcher.fetch(source)

# Persist the `Last-Modified` short-circuit state. The reusable crawler workflow
# only auto-commits `data/*` and `index*.yaml`; other files must be staged
# explicitly (as the sibling data repos do for their index files), or
# `last_modified.txt` never survives between CI runs and the incremental
# short-circuit can never trigger.
system("git", "add", "last_modified.txt") if File.exist?("last_modified.txt")

# `index-v1` serves the released relaton-iso gem line, whose identifiers are
# parsed with pubid v1. pubid v1 and the pubid v2 loaded above both define
# `Pubid::Iso::Identifier` and cannot coexist in one process, so rebuild it in a
# separate process with its own bundle. On a full refresh the index file was
# removed above, so this rebuilds from scratch; on an incremental run it merges
# into the existing index (no deletions occur, so no dangling).
Bundler.with_unbundled_env do
  ok = system(RbConfig.ruby, File.join(__dir__, "build_index_v1.rb"))
  abort "build_index_v1.rb failed" unless ok
end
