# frozen_string_literal: true

source "https://rubygems.org"

gem "relaton", git: "https://github.com/relaton/relaton.git", branch: "main"

# Pin pubid to the same ref as relaton `main` (see its Gemfile). `27454393` is
# the last pubid `main` commit that still parses with parslet. The commits after
# it parse through parsanol PG artifacts, but pubid does not declare parsanol in
# its gemspec, so on pubid `main` every parse fails with `uninitialized constant
# Pubid::Parg::Backend::Parsanol` and the crawl wipes the index (issue #42).
# Move to `main` once pubid depends on a released parsanol.
pubid = { git: "https://github.com/metanorma/pubid.git", ref: "27454393" }
# A `local.pubid` override needs `branch:`. Without the override, `branch:`
# makes Bundler fetch only the tip (`--depth 1`) and lose the pinned ref.
pubid[:branch] = "main" if Bundler.settings["local.pubid"]
gem "pubid", **pubid

gem "rake"

group :test do
  gem "rspec", "~> 3.13"
end
