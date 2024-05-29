# frozen_string_literal: true

require 'relaton_iso'

# Run data fetcher
# RelatonIso::DataFetcher.fetch

# index_file = RelatonIso::HitCollection::INDEXFILE
# index = Relaton::Index.find_or_create :iso, file: index_file

# Dir["data/**/*.yaml"].each do |f|
#   hash = YAML.load_file f
#   item_hash = RelatonIso::HashConverter.hash_to_bib(hash)
#   bib = RelatonIsoBib::IsoBibliographicItem.new(**item_hash)
#   id = bib.docidentifier.detect(&:primary)
#   index.add_or_update id.to_h, f
# end

# Dir["static/**/*.yaml"].each do |f|
#   hash = YAML.load_file f
#   item_hash = RelatonIso::HashConverter.hash_to_bib(hash)
#   bib = RelatonIsoBib::IsoBibliographicItem.new(**item_hash)
#   id = bib.docidentifier.detect(&:primary)
#   index.add_or_update id.to_h, f
# end
# index.save

# `git add #{RelatonIso::Queue::FILE}`
