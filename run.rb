require './simple_language/executor.rb'

filename = ARGV[0] || 'examples/sample.js'
script = File.read(filename)
class HelloWorld
  def initialize
    @run_count = 0
  end
  def some_external_method(a,b)
    @run_count = @run_count + 1
    return a*a*b*b
  end
end
hw = HelloWorld.new
executor = SimpleLanguage::Executor.new
executor.register("foreign_func", hw, :some_external_method)
output = executor.run(script)

