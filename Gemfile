# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "psych", "~> 5.2.6" # to avoid psych 5.3.0 breaking yaml parsing
# The lutaml-integration branch pin alone selects the source; a version
# constraint here rots every time that branch is version-bumped (the
# 2026-10-04 crawl died on bundle exit 7 when the branch reached 2.1.6).
gem "relaton-iso", github: "relaton/relaton-iso", branch: "lutaml-integration"
