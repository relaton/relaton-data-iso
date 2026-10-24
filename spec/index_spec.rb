# frozen_string_literal: true

# Each document file must be indexed once. Two ids on one file means one
# document overwrote another on disk (issue #31), so a lookup for one of the
# ids returns the wrong document.
RSpec.describe "index files" do
  def duplicate_files(name)
    path = File.expand_path("../#{name}", __dir__)
    files = File.foreach(path).filter_map { |line| line[/^  :file: (.+)$/, 1] }
    files.tally.select { |_, count| count > 1 }.keys
  end

  it "index-v1.yaml has no file indexed twice" do
    expect(duplicate_files("index-v1.yaml")).to be_empty
  end

  it "index-v2.yaml has no file indexed twice" do
    # Relaton::Iso::DataFetcher#fetch_pub calls `output_file`, which maps "."
    # and "-" alike to "-": `ISO/DIS 15869.3` and `ISO/DIS 15869-3` collide.
    # Fixed when the ISO flavor uses Relaton::Core::DataFetcher#unique_output_file.
    pending "ISO DataFetcher does not use unique_output_file yet"
    expect(duplicate_files("index-v2.yaml")).to be_empty
  end
end
