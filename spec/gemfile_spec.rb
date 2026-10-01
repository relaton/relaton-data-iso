# frozen_string_literal: true

require "bundler"

RSpec.describe "Gemfile" do
  subject(:options) do
    gemfile = File.expand_path("../Gemfile", __dir__)
    Bundler::Dsl.new.tap { |dsl| dsl.eval_gemfile(gemfile) }
      .dependencies.find { |dep| dep.name == "pubid" }.source.options
  end

  before do
    allow(Bundler.settings).to receive(:[]).and_call_original
    allow(Bundler.settings).to receive(:[]).with("local.pubid").and_return(local_pubid)
  end

  # With `branch:` Bundler clones only the branch tip (`--depth 1`), so an
  # older pinned `ref:` is not in the clone and `bundle install` fails in CI.
  context "without a local.pubid override" do
    let(:local_pubid) { nil }

    it "pins pubid by ref without a branch" do
      expect(options).to include("ref" => "27454393")
      expect(options).not_to have_key("branch")
    end
  end

  context "with a local.pubid override" do
    let(:local_pubid) { "../../metanorma/pubid" }

    it "adds the branch that the override needs" do
      expect(options).to include("ref" => "27454393", "branch" => "main")
    end
  end
end
