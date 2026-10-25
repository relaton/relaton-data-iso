# frozen_string_literal: true

require "yaml"

# Each document file must be indexed once. Two ids on one file means one
# document overwrote another on disk (issue #31), so a lookup for one of the
# ids returns the wrong document. Each id must be indexed once too, and each
# indexed file must exist.
RSpec.describe "index files" do
  root = File.expand_path("..", __dir__)

  %w[index-v1.yaml index-v2.yaml].each do |name|
    context name do
      entries = YAML.safe_load_file(File.join(root, name), permitted_classes: [Symbol], aliases: true)

      def duplicates(values)
        values.tally.select { |_, count| count > 1 }.keys
      end

      it "has no file indexed twice" do
        expect(duplicates(entries.map { |e| e[:file] })).to be_empty
      end

      it "has no id indexed twice" do
        expect(duplicates(entries.map { |e| e[:id] })).to be_empty
      end

      it "has no missing file" do
        missing = entries.map { |e| e[:file] }.reject { |f| File.exist?(File.join(root, f)) }
        expect(missing).to be_empty
      end
    end
  end
end
