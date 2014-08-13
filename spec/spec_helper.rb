require 'ostruct'
require 'coveralls'
require 'cypherites'
require 'support/runner'

Coveralls.wear!


RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end