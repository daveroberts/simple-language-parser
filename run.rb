require 'pry'
require 'pp'
require 'json'
require './newparser.rb'

filename = ARGV[0] || 'examples/newsample.js'
script = File.read(filename)
output = run(script)

