require './simple_language/executor.rb'

filename = ARGV[0] || 'examples/sample.js'
script = File.read(filename)
module HelloWorld
  def self.some_external_method(a,b)
    return a*a*b*b
  end
end
executor = SimpleLanguage::Executor.new
executor.register("foreign_func", 'HelloWorld', :some_external_method)
output = executor.run(script)

