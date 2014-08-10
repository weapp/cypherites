require 'cypherites'
require 'ostruct'

require 'support/runner'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end