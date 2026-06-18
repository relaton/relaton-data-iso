# frozen_string_literal: true

# Rebuild `index-v1.yaml` from the curated `data/` (and `static/`) tree.
#
# `index-v1` is the index consumed by the *released* relaton-iso gem line, which
# parses identifiers with pubid v1 (`pubid-iso`). The crawler proper runs the
# monorepo gem, which loads pubid v2 (`pubid`) and writes `index-v2`. pubid v1
# and pubid v2 both define `Pubid::Iso::Identifier` and cannot be loaded in the
# same process, so this script runs standalone (spawned by `crawler.rb` in a
# clean bundler env) with its own pubid-v1 dependency set.
#
# It reads only the primary docidentifier *string* from each YAML file (no
# schema deserialization), so it is immune to data-model drift between the two
# gem lines.

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "psych", "~> 5.2.6" # match the crawler: avoid psych 5.3.0 yaml breakage
  gem "pubid-iso", "~> 1.15"
  gem "relaton-index"
end

require "fileutils"
require "yaml"

INDEX_FILE = "index-v1.yaml"

# crawler.rb only runs this after a full replace of `data/`, so rebuild from
# scratch: drop any existing index first (Type would otherwise read it back in
# and merge, leaving entries for files that have since been removed dangling).
# Removing the file also skips parsing it.
FileUtils.rm_f(INDEX_FILE)

index = Relaton::Index::Type.new(
  :iso, nil, INDEX_FILE, nil, Pubid::Iso::Identifier
)

# Pull the primary docidentifier content (a plain string) out of a data file
# without deserializing the whole bibliographic item.
def primary_docid(file)
  hash = YAML.safe_load_file(file)
  return nil unless hash.is_a?(Hash)

  did = Array(hash["docidentifier"]).find { |d| d.is_a?(Hash) && d["primary"] }
  did && did["content"]
end

count = 0
failures = []

["data/**/*.yaml", "static/**/*.yaml"].each do |glob|
  Dir[glob].each do |file|
    content = primary_docid(file)
    next unless content

    index.add_or_update(Pubid::Iso::Identifier.parse(content), file)
    count += 1
  rescue StandardError => e
    failures << "#{file}: #{e.class}: #{e.message}"
  end
end

index.save

puts "index-v1: wrote #{count} entries to #{INDEX_FILE}"
unless failures.empty?
  warn "index-v1: #{failures.size} file(s) could not be indexed:"
  warn failures.first(20).join("\n")
end
