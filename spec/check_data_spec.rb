# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

# check_data.rb runs in CI (relaton/support check-data.yml) over `static/`.
# Run it as CI does: a separate process, from the repo root.
RSpec.describe "check_data.rb" do
  root = File.expand_path("..", __dir__)

  def run_check(root, *args)
    Open3.capture2e(RbConfig.ruby, "check_data.rb", *args, chdir: root)
  end

  it "passes on the static files" do
    out, status = run_check(root)
    expect(status).to be_success, out
  end

  it "fails on a file with no primary id" do
    Dir.mktmpdir do |dir|
      src = File.read(File.join(root, "static/iso-tc-184-sc-4-n3500.yaml"))
      File.write(File.join(dir, "bad.yaml"), src.sub("  primary: true\n", ""))
      out, status = run_check(root, File.join(dir, "*.yaml"))
      expect(status).not_to be_success
      expect(out).to include("No primary id")
    end
  end

  it "fails when no file matches the glob" do
    out, status = run_check(root, "nonexistent/*.yaml")
    expect(status).not_to be_success
    expect(out).to include("No files match nonexistent/*.yaml")
  end

  it "fails on a nested value the model changes" do
    Dir.mktmpdir do |dir|
      src = File.read(File.join(root, "static/iso-tc-184-sc-4-n3500.yaml"))
      # The model writes this date in a different form.
      File.write(File.join(dir, "bad.yaml"),
                 src.sub("at: '2020-08-09'", "at: '2020-8-9'"))
      out, status = run_check(root, File.join(dir, "*.yaml"))
      expect(status).not_to be_success
      expect(out).to include("- 2020-8-9 (at date[0].at)")
    end
  end

  it "fails on a file with data the model drops" do
    Dir.mktmpdir do |dir|
      src = File.read(File.join(root, "static/iso-tc-184-sc-4-n3500.yaml"))
      File.write(File.join(dir, "bad.yaml"), "#{src}unknown_key: value\n")
      out, status = run_check(root, File.join(dir, "*.yaml"))
      expect(status).not_to be_success
      expect(out).to include("Parsing #{dir}/bad.yaml failed. " \
                             "Parsed content doesn't match to source.")
      expect(out).to include("unknown_key")
    end
  end
end
