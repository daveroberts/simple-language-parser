require 'pry'
require 'json'
require 'pp'

script = ARGV[0] || 'sample.scrape.lisp'
file = File.read(script)
file = file.split("\n").select{|l|!l.start_with?';'}.join(" ")
program = file.split " "

def go(url)
  #puts "Navigating browser to #{url}"
end

def grablinks()
  #puts "Grabbing links from current page"
  return ["link1","link2","link3","link4"]
end

def click(sel)
  #puts "clicked on #{sel}"
  # dummy click on selector
end

def parselinks(links, regex)
  #puts "parsing #{links.count} links with #{regex}"
  chosen_links = []
  chosen = true
  links.each do |link|
    chosen_links.push(link) if chosen
    chosen = !chosen
  end
  return chosen_links
end

def grabcss(sel)
  return "Content from #{sel}"
end

def has_element?(sel)
  #return sel.start_with? "true"
  return [true,false].sample
end

@variables = {}

class NullPointer < Exception; end
class InvalidParameter < Exception; end
class UnknownCommand < Exception; end
class Break < Exception; end

def run(program)
  stack = program.dup
  values = []
  loop do
    break if stack.length == 0
    values.concat pop(stack)
  end
  return values
end

def pop(stack)
  cmd = stack.shift
  if cmd == '('
    block = []
    count = 1
    loop do
      loop_cmd = stack.shift
      count = count + 1 if loop_cmd == '('
      count = count - 1 if loop_cmd == ')'
      break if count == 0
      block.push loop_cmd
    end
    block_val = run(block)
    return [block_val]
  elsif cmd == "{"
    block = []
    count = 1
    loop do
      loop_cmd = stack.shift
      count = count + 1 if loop_cmd == '{'
      count = count - 1 if loop_cmd == '}'
      break if count == 0
      block.push loop_cmd
    end
    return [block]
  elsif cmd == 'fun'
    sym = pop(stack)[0]
    params = pop(stack)[0]
    block = pop(stack)[0]
    @variables[sym] = { params: params, block: block }
    return []
  elsif cmd == 'call'
    sym = pop(stack)[0]
    param_values = pop(stack)[0]
    params = @variables[sym][:params]
    block = @variables[sym][:block]
    params.each_with_index do |p,i|
      @variables[p] = param_values[i]
    end
    values = run(block)
    return [values.pop]
  elsif cmd.start_with? '"'
    return [cmd[1..cmd.length-2]]
  elsif cmd.start_with? '&'
    sym = cmd[1..cmd.length].to_sym
    raise NullPointer, "Null Pointer: #{sym}" if !@variables.has_key? sym
    return [@variables[sym]]
  elsif cmd.match /^\d+$/
    return [cmd.to_i]
  elsif cmd.start_with? ":"
    return [cmd[1..cmd.length].to_sym]
  elsif cmd.start_with? "/"
    return [Regexp.new(cmd)]
  elsif cmd == 'set'
    sym = pop(stack)[0]
    raise InvalidParameter, "Invalid Parameter: `set` param #1, excepted symbol, found #{sym.class}" if sym.class != Symbol
    value = pop(stack)[0]
    @variables[sym] = value
    return []
  elsif cmd == '+'
    a = pop(stack)[0]
    b = pop(stack)[0]
    return [a + b]
  elsif cmd == '!'
    bool = pop(stack)[0]
    return [!bool]
  elsif cmd == 'get'
    sym = pop(stack)[0]
    return [@variables[sym]]
  elsif cmd == 'hashmap'
    sym = pop(stack)[0]
    @variables[sym] = {}
    return []
  elsif cmd == 'setmap'
    map = pop(stack)[0]
    sym = pop(stack)[0]
    val = pop(stack)[0]
    @variables[map][sym] = val
    return []
  elsif cmd == 'array'
    sym = pop(stack)[0]
    @variables[sym] = []
    return []
  elsif cmd == 'push'
    sym = pop(stack)[0]
    val = pop(stack)[0]
    @variables[sym].push(val)
    return []
  elsif cmd == 'join'
    arr = pop(stack)[0]
    return [arr.join]
  elsif cmd == 'for'
    collection = pop(stack)[0]
    sym = pop(stack)[0]
    block = pop(stack)[0]
    collection.each do |item|
      @variables[sym] = item
      begin
        val = run(block.dup)
      rescue Break
        break
      end
    end
    return []
  elsif cmd == 'loop'
    block = pop(stack)[0]
    loop do
      begin
        values = run(block.dup)
      rescue Break
        break
      end
    end
    return []
  elsif cmd == 'break'
    raise Break
  elsif cmd == 'if'
    predicate = pop(stack)[0]
    t_block = pop(stack)[0]
    raise InvalidParameter, "Invalid Parameter: `if` param #2, excepted Block, found #{t_block.class}" if t_block.class != Array
    f_block = pop(stack)[0]
    raise InvalidParameter, "Invalid Parameter: `if` param #3, excepted Block, found #{f_block.class}" if f_block.class != Array
    run(t_block) if predicate
    run(f_block) if !predicate
    return []
  elsif cmd == 'print'
    val = pop(stack)[0]
    puts val
    return []
  elsif cmd == 'json'
    val = pop(stack)[0]
    return [val.to_json]
  elsif cmd == 'go'
    url = pop(stack)[0]
    go(url)
    return []
  elsif cmd == 'grablinks'
    return [grablinks]
  elsif cmd == 'grabcss'
    sel = pop(stack)[0]
    return [grabcss(sel)]
  elsif cmd == 'parselinks'
    links = pop(stack)[0]
    regex = pop(stack)[0]
    return [parselinks(links, regex)]
  elsif cmd == 'has_element?'
    sel = pop(stack)[0]
    return [has_element?(sel)]
  elsif cmd == 'click'
    sel = pop(stack)[0]
    click(sel)
    return []
  elsif cmd == 'type'
    info = pop(stack)[0]
    sel = pop(stack)[0]
    # call to type
    return []
  elsif cmd == 'submit'
    # call to submit
    return []
  else
    raise UnknownCommand, "Unknown command: #{cmd}"
  end
end

json = run(program)[0]
pp JSON.parse(json)
