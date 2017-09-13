require 'pry'
require 'json'

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

def parselinks(options)
  chosen_links = []
  chosen = true
  options[:links].each do |link|
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

class NullPointer < Exception; end
class InvalidParameter < Exception; end
class UnknownCommand < Exception; end
class InfiniteLoop < Exception; end
class MismatchedTag < Exception; end
class Break < Exception; end
class Return < Exception
  attr_reader :value
  def initialize(v)
    @value = v
  end
end

def interactive
  variables = {}
  loop do
    print ">> "
    line = gets
    output = run(line, variables)
    puts output
  end
end

def run(script, variables = {})
  program = tokenize script
  run_block(program, variables)
end

def tokenize(script)
  script = script.split("\n").select{|l|!l.start_with?';'}.join(" ")
  strings = script.scan(/\".*?[^\\]\"/)
  script = script.gsub(/\".*?[^\\]\"/, "__STRING__")
  program = script.split " "
  i=0
  while i < program.length do
    if program[i] == "__STRING__"
      program[i] = strings.shift
    end
    i = i + 1
  end
  return program
end

def run_block(program, variables, values=[])
  stack = program.dup
  loop do
    break if stack.length == 0
    values.concat pop(stack, variables)
  end
  return values
end

def popval(stack, variables)
  value = pop(stack, variables)[0]
  value = variables[value] if value.class == Symbol
  return value
end

def pop(stack, variables)
  cmd = stack.shift
  if cmd == '('
    block = []
    count = 1
    loop do
      raise InfiniteLoop, "`(` without corresponding `)`.  (Make sure you have spaces around parenthesis)" if stack.count == 0
      loop_cmd = stack.shift
      count = count + 1 if loop_cmd == '('
      count = count - 1 if loop_cmd == ')'
      break if count == 0
      block.push loop_cmd
    end
    block_val = run_block(block, variables)
    return [block_val]
  elsif cmd == "{"
    block = []
    count = 1
    loop do
      raise InfiniteLoop, "`{` without corresponding `}`.  (Make sure you have spaces around curly braces)" if stack.count == 0
      loop_cmd = stack.shift
      count = count + 1 if loop_cmd == '{'
      count = count - 1 if loop_cmd == '}'
      break if count == 0
      block.push loop_cmd
    end
    return [block]
  elsif cmd == ')'
    raise MismatchedTag, "`)` without earlier `(`.  (Make sure you have spaces around parenthesis)"
  elsif cmd == '}'
    raise MismatchedTag, "`}` without earlier `{`.  (Make sure you have spaces around curly braces)"
  elsif cmd == 'fun'
    name = pop(stack, variables)[0]
    params = popval(stack, variables)
    block = popval(stack, variables)
    variables[name] = { fun: true, params: params, block: block }
    return []
  elsif cmd == 'return'
    value = popval(stack, variables)
    raise Return.new(value)
  elsif cmd.start_with? '"'
    return [cmd[1..cmd.length-2]]
  elsif cmd.match /^\d+$/
    return [cmd.to_i]
  elsif cmd.start_with? ":"
    return [cmd[1..cmd.length].to_sym]
  elsif cmd.start_with? '&'
    return [variables[cmd[1..cmd.length].to_sym]]
  elsif cmd == 'true'
    return [true]
  elsif cmd == 'false'
    return [false]
  elsif cmd.start_with? "/"
    return [Regexp.new(cmd)]
  elsif cmd == 'set'
    sym = stack.shift.to_sym
    value = popval(stack, variables)
    variables[sym] = value    
    return []
  elsif cmd == '-'
    a = popval(stack, variables)
    b = popval(stack, variables)
    return [a - b]
  elsif cmd == '+'
    a = popval(stack, variables)
    b = popval(stack, variables)
    return [a + b]
  elsif cmd == '='
    a = popval(stack, variables)
    b = popval(stack, variables)
    return [a == b]
  elsif cmd == '!'
    bool = popval(stack, variables)
    return [!bool]
  elsif cmd == 'get'
    sym = pop(stack, variables)[0]
    return [variables[sym]]
  elsif cmd == 'obj'
    block = pop(stack, variables)[0]
    obj = {}
    loop do
      break if block.count == 0
      sym = pop(block, variables)[0]
      val = popval(block, variables)
      obj[sym] = val
    end
    return [obj]
  elsif cmd == 'setprop'
    obj = popval(stack, variables)
    sym = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `setprop` param #2, expected Symbol, found #{sym.class}" if sym.class != Symbol
    val = popval(stack, variables)
    obj[sym] = val
    return []
  elsif cmd == 'getprop'
    obj = popval(stack, variables)
    sym = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `getprop` param #2, expected Symbol, found #{sym.class}" if sym.class != Symbol
    return [obj[sym]]
  elsif cmd == 'getitem'
    arr = popval(stack, variables)
    index = popval(stack, variables)
    return [arr[index]]
  elsif cmd == 'push'
    collection = popval(stack, variables)
    val = popval(stack, variables)
    collection.push(val)
    return []
  elsif cmd == 'join'
    arr = popval(stack, variables)
    return [arr.join]
  elsif cmd == 'each'
    collection = popval(stack, variables)
    sym = pop(stack, variables)[0]
    block = popval(stack, variables)
    locals = variables.dup
    collection.each do |item|
      locals[sym] = item
      begin
        val = run_block(block.dup, locals)
      rescue Break
        break
      end
    end
    return []
  elsif cmd == 'first'
    collection = popval(stack, variables)
    return [collection.first]
  elsif cmd == 'map'
    collection = popval(stack, variables)
    sym = pop(stack, variables)[0]
    block = popval(stack, variables)
    new_collection = []
    locals = variables.dup
    collection.each do |item|
      locals[sym] = item
      val = run_block(block.dup, locals).pop
      new_collection.push(val)
    end
    return [new_collection]
  elsif cmd == 'loop'
    block = popval(stack, variables)
    values = []
    loop do
      begin
        run_block(block.dup, variables, values)
      rescue Break
        break
      end
    end
    return [values]
  elsif cmd == 'break'
    raise Break
  elsif cmd == 'if'
    predicate = popval(stack, variables)
    t_block = popval(stack, variables)
    f_block = popval(stack, variables)
    values = run_block(t_block, variables) if predicate
    values = run_block(f_block, variables) if !predicate
    return values
  elsif cmd == 'print'
    val = popval(stack, variables)
    puts val
    return []
  elsif cmd == 'json'
    val = popval(stack, variables)
    return [val.to_json]
  elsif cmd == 'debug'
    binding.pry
    return []
  elsif cmd == 'go'
    url = popval(stack, variables)
    go(url)
    return []
  elsif cmd == 'grablinks'
    return [grablinks]
  elsif cmd == 'grabcss'
    sel = popval(stack, variables)
    return [grabcss(sel)]
  elsif cmd == 'parselinks'
    options = popval(stack, variables)
    return [parselinks(options)]
  elsif cmd == 'has_element?'
    sel = popval(stack, variables)
    return [has_element?(sel)]
  elsif cmd == 'click'
    sel = popval(stack, variables)
    click(sel)
    return []
  elsif cmd == 'type'
    info = popval(stack, variables)
    sel = popval(stack, variables)
    # call to type
    return []
  elsif cmd == 'screenshot'
    params = popval(stack)
    hsh = {}
    return ["SCREENSHOT DATA HERE params(#{params})"]
  elsif cmd == 'submit'
    # call to submit
    return []
  else
    return [sym_to_val(cmd, stack, variables)]
  end
end

def sym_to_val(cmd, stack, variables)
  if variables.has_key? cmd.to_sym
    if variables[cmd.to_sym].class == Hash && variables[cmd.to_sym][:fun]
      fun = variables[cmd.to_sym]
      locals = variables.dup
      fun[:params].each do |p|
        locals[p] = popval(stack, variables)
      end
      block = fun[:block]
      values = nil
      begin
        values = run_block(block, locals)
      rescue Return => ret
        return ret.value
      end
      return values.pop
    else
      return variables[cmd.to_sym]
    end
  end
  return cmd.to_sym
end
