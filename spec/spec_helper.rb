$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'pry'
require "stack_car"

RSpec.configure do |configure|
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
end
