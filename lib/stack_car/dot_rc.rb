# frozen_string_literal: true
require 'pathname'
module StackCar
  class DotRc
    include Thor::Shell

    def initialize
      @file = find_file
      say_status :load, 'not found', :red && return unless @file
      say_status :load, @file
      load(@file)
    end

    def find_file
      path = nil
      Pathname(Dir.pwd).ascend do |p|
        if File.directory?(p) && File.exist?(File.join(p, '.stack_car_rc'))
          path = File.join(p, '.stack_car_rc')
          break
        end
      end
      path
    end
  end
end
