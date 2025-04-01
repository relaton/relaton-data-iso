# frozen_string_literal: true

require "relaton/iso/data_fetcher"

ENV["GITHUB_TOKEN"] = ARGV.last if ARGV.last

# Run data fetcher. It will download 10,000 ISO standards and
# save them to the default data directory in default YAML format.
# Next run it will download next 10,000 standards.
Relaton::Iso::DataFetcher.fetch

index_file = "#{Relaton::Iso::HitCollection::INDEXFILE}.yaml"
index = Relaton::Index.find_or_create :iso, file: index_file

Dir["data/**/*.yaml"].each do |f|
  item = Relaton::Iso::Item.from_yml File.read(f, encoding: "UTF-8")
  id = item.docidentifier.detect(&:primary)
  index.add_or_update id.to_h, f
end

Dir["static/**/*.yaml"].each do |f|
  item = Relaton::Iso::Item.from_yml File.read(f, encoding: "UTF-8")
  id = item.docidentifier.detect(&:primary)
  index.add_or_update id.to_h, f
end
index.save

`git add #{Relaton::Iso::Queue::FILE}`
