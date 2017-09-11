require 'pry'
require 'json'

script = ARGV[0] || 'sample.scrape'
file = File.read(script)
program = file.split " "

def go(url)
  puts "Navigating browser to #{url}"
end

def grablinks()
  puts "Grabbing links from current page"
  return ["link1","link2","link3","link4"]
end

def click(sel)
  puts "clicked on #{sel}"
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
  #puts "grabbing #{sel} from page"
  return "Content from #{sel}"
end

def has_element?(sel)
  #return sel.start_with? "true"
  return [true,false].sample
end

@variables = {}

def run(program)
  stack = program
  value = nil
  loop do
    break if stack.length == 0
    value = pop(stack)
  end
  return value
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
    return block_val
  elsif cmd == '{'
    block = []
    count = 1
    loop do
      loop_cmd = stack.shift
      count = count + 1 if loop_cmd == '{'
      count = count - 1 if loop_cmd == '}'
      break if count == 0
      block.push loop_cmd
    end
    return block
  elsif cmd == '['
    arr = []
    count = 1
    loop do
      item = stack.shift
      count = count + 1 if item == '['
      count = count - 1 if item == ']'
      break if count == 0
      arr.push item
    end
    return arr
  elsif cmd.start_with? '"'
    return cmd[1..cmd.length-2]
  elsif cmd.start_with? '&'
    sym = cmd[1..cmd.length].to_sym
    return @variables[sym]
  elsif cmd.match /\d+/
    return cmd.to_i
  elsif cmd.start_with? ":"
    return cmd[1..cmd.length].to_sym
  elsif cmd.start_with? "/"
    return Regexp.new(cmd)
  elsif cmd == 'set'
    sym = pop(stack)
    value = pop(stack)
    @variables[sym] = value
  elsif cmd == '+'
    a = pop(stack)
    b = pop(stack)
    return a + b
  elsif cmd == 'get'
    sym = pop(stack)
    return @variables[sym]
  elsif cmd == 'map'
    sym = pop(stack)
    @variables[sym] = {}
  elsif cmd == 'setmap'
    map = pop(stack)
    sym = pop(stack)
    val = pop(stack)
    @variables[map][sym] = val
  elsif cmd == 'arr'
    sym = pop(stack)
    @variables[sym] = []
  elsif cmd == 'push'
    sym = pop(stack)
    val = pop(stack)
    @variables[sym].push(val)
  elsif cmd == 'join'
    arr = pop(stack)
    return arr.join
  elsif cmd == 'for'
    collection = pop(stack)
    sym = pop(stack)
    block = pop(stack)
    collection.each do |item|
      @variables[sym] = item
      run(block)
    end
  elsif cmd == 'loop'
    block = pop(stack)
    loop do
      val = run(block.dup)
      break if val == 'BREAK'
    end
  elsif cmd == 'break'
    stack.clear
    return 'BREAK'
  elsif cmd == 'if'
    predicate = pop(stack)
    t_block = pop(stack)
    f_block = pop(stack)
    value = run(t_block) if predicate
    value = run(f_block) if !predicate
  elsif cmd == 'json'
    val = pop(stack)
    return val.to_json
  elsif cmd == 'go'
    url = pop(stack)
    go(url)
  elsif cmd == 'grablinks'
    return grablinks()
  elsif cmd == 'grabcss'
  elsif cmd == 'parselinks'
    links = pop(stack)
    regex = pop(stack)
    return parselinks(links, regex)
  elsif cmd == 'has_element?'
    sel = pop(stack)
    return has_element? sel
  elsif cmd == 'click'
    sel = pop(stack)
    click(sel)
  else
    puts "I don't know how to `#{cmd}`"
    exit(-1)
  end
end

value = run(program)
puts value
