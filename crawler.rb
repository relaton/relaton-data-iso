# frozen_string_literal: true

require 'relaton_iso'

# Run data fetcher
RelatonIso::DataFetcher.fetch

index_file = RelatonIso::HitCollection::INDEX_FILE
index = Relaton::Index.find_or_create :iso, file: index_file
Dir["static/**/*.yaml"].each do |f|
  hash = YAML.load_file f
  item_hash = ::RelatonIsoBib::HashConverter.hash_to_bib(hash)
  bib = RelatonIsoBib::IsoBibliographicItem.new(**item_hash)
  pubid = bib.docidentifier.detect(&:primary).id
  index.add_or_update pubid.to_s, f
end
index.save
