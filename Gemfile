# frozen_string_literal: true

source "https://rubygems.org"

gem "relaton", git: "https://github.com/relaton/relaton.git", branch: "main"

# Match relaton main: pubid 2.0.0.pre.alpha.21 parses through the
# released parsanol (>= 1.3.62 on rubygems); the parslet-era ref pin
# broke resolution once relaton main required ~> .21 (issue #42).
gem "pubid", "~> 2.0.0.pre.alpha.21"

gem "rake"

group :test do
  gem "rspec", "~> 3.13"
end
