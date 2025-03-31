require_relative './stack_car/version'
require_relative './stack_car/os'
require_relative './stack_car/proxy'
require_relative './stack_car/cli'
require_relative './stack_car/dot_rc'

##
# Ruby 3.x removed {File.exists?} in favor of {File.exist?}.  This shim ensures that we can run
# stack_car in both Ruby 2.7 and Ruby 3.x land.
unless File.respond_to?(:exists?)
  # We're aliasing the class method exist?, hence the `class << File` antics.
  class << File
    alias exists? exist?
  end
end

module StackCar
  # Your code goes here...
end
