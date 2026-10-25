# frozen_string_literal: true

require "bundler"

RSpec.describe "Gemfile" do
  subject(:pubid) do
    gemfile = File.expand_path("../Gemfile", __dir__)
    Bundler::Dsl.new.tap { |dsl| dsl.eval_gemfile(gemfile) }
      .dependencies.find { |dep| dep.name == "pubid" }
  end

  # relaton `main` requires pubid ~> 2.0.0.pre.alpha.21, which parses through
  # the released parsanol. A git pin to an older (parslet-era) pubid ref does
  # not resolve against it, and the crawler's `bundle install` fails (issue #42).
  it "takes pubid from rubygems, not from git" do
    expect(pubid.source).to be_nil
  end

  it "requires the pubid 2.0.0.pre.alpha.21 line" do
    expect(pubid.requirement).to eq Gem::Requirement.new("~> 2.0.0.pre.alpha.21")
  end
end
