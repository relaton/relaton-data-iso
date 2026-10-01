# frozen_string_literal: true

require "pubid"
require_relative "../pubid_check"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
end
