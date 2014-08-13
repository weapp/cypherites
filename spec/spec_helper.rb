require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'coveralls'
Coveralls.wear!

require 'ostruct'
require 'cypherites'
require 'support/runner'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end