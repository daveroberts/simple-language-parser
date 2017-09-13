require 'pry'
require 'pp'
require 'json'
require './parser.rb'

filename = ARGV[0] || 'examples/sample.scrape.lisp'
script = File.read(filename)
values = run(script)

begin
  pp JSON.parse(values.dup.pop)
rescue
  puts values
end
