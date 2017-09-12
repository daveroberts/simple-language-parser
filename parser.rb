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

def run(script)
  script = script.split("\n").select{|l|!l.start_with?';'}.join(" ")
  program = script.split " "
  run_block(program, {})
end

def run_block(program, variables)
  stack = program.dup
  values = []
  loop do
    break if stack.length == 0
    values.concat pop(stack, variables)
  end
  return values
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
    sym = pop(stack, variables)[0]
    params = pop(stack, variables)[0]
    block = pop(stack, variables)[0]
    variables[sym] = { params: params, block: block }
    return []
  elsif cmd == 'call'
    sym = pop(stack, variables)[0]
    param_values = pop(stack, variables)[0]
    params = variables[sym][:params]
    block = variables[sym][:block]
    locals = variables.dup
    params.each_with_index do |p,i|
      locals[p] = param_values[i]
    end
    begin
      values = run_block(block, locals)
    rescue Return => ret
      return [ret.value]
    end
    return [values.pop]
  elsif cmd == 'return'
    value = pop(stack, variables)[0]
    raise Return.new(value)
  elsif cmd.start_with? '"'
    return [cmd[1..cmd.length-2]]
  elsif cmd.start_with? '&'
    sym = cmd[1..cmd.length].to_sym
    raise NullPointer, "Null Pointer: #{sym}" if !variables.has_key? sym
    return [variables[sym]]
  elsif cmd.match /^\d+$/
    return [cmd.to_i]
  elsif cmd.start_with? ":"
    return [cmd[1..cmd.length].to_sym]
  elsif cmd.start_with? "/"
    return [Regexp.new(cmd)]
  elsif cmd == 'set'
    sym = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `set` param #1, excepted symbol, found #{sym.class}" if sym.class != Symbol
    value = pop(stack, variables)[0]
    variables[sym] = value
    return [value]
  elsif cmd == '-'
    a = pop(stack, variables)[0]
    b = pop(stack, variables)[0]
    return [a - b]
  elsif cmd == '+'
    a = pop(stack, variables)[0]
    b = pop(stack, variables)[0]
    return [a + b]
  elsif cmd == '='
    a = pop(stack, variables)[0]
    b = pop(stack, variables)[0]
    return [a == b]
  elsif cmd == '!'
    bool = pop(stack, variables)[0]
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
      val = pop(block, variables)[0]
      obj[sym] = val
    end
    return [obj]
  elsif cmd == 'setmap'
    map = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `setmap` param #1, expected Symbol, found #{map.class}" if map.class != Symbol
    sym = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `setmap` param #2, expected Symbol, found #{sym.class}" if sym.class != Symbol
    val = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `setmap` param #3, expected value, found Symbol (#{val})" if val.class == Symbol
    variables[map][sym] = val
    return [variables[map]]
  elsif cmd == 'push'
    sym = pop(stack, variables)[0]
    val = pop(stack, variables)[0]
    variables[sym].push(val)
    return []
  elsif cmd == 'join'
    arr = pop(stack, variables)[0]
    return [arr.join]
  elsif cmd == 'each'
    collection = pop(stack, variables)[0]
    sym = pop(stack, variables)[0]
    block = pop(stack, variables)[0]
    locals = variables.dup
    collection.each do |item|
      locals[sym] = item
      begin
        val = run_block(block.dup, locals)
      rescue Break
        break
      rescue Return
        xyzzy
      end
    end
    return []
  elsif cmd == 'map'
    collection = pop(stack, variables)[0]
    sym = pop(stack, variables)[0]
    block = pop(stack, variables)[0]
    new_collection = []
    locals = variables.dup
    collection.each do |item|
      locals[sym] = item
      val = run_block(block.dup, locals).pop
      new_collection.push(val)
    end
    return [new_collection]
  elsif cmd == 'loop'
    block = pop(stack, variables)[0]
    loop do
      begin
        values = run_block(block.dup, variables)
      rescue Break
        break
      end
    end
    return []
  elsif cmd == 'break'
    raise Break
  elsif cmd == 'if'
    predicate = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `if` param #1, excepted true or false, found #{predicate.class}" if predicate.class != TrueClass && predicate.class != FalseClass
    t_block = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `if` param #2, excepted Block, found #{t_block.class}" if t_block.class != Array
    f_block = pop(stack, variables)[0]
    raise InvalidParameter, "Invalid Parameter: `if` param #3, excepted Block, found #{f_block.class}" if f_block.class != Array
    run_block(t_block, variables) if predicate
    run_block(f_block, variables) if !predicate
    return []
  elsif cmd == 'print'
    val = pop(stack, variables)[0]
    puts val
    return []
  elsif cmd == 'json'
    val = pop(stack, variables)[0]
    return [val.to_json]
  elsif cmd == 'debug'
    binding.pry
    return []
  elsif cmd == 'go'
    url = pop(stack, variables)[0]
    go(url)
    return []
  elsif cmd == 'grablinks'
    return [grablinks]
  elsif cmd == 'grabcss'
    sel = pop(stack, variables)[0]
    return [grabcss(sel)]
  elsif cmd == 'parselinks'
    links = pop(stack, variables)[0]
    regex = pop(stack, variables)[0]
    return [parselinks(links, regex)]
  elsif cmd == 'has_element?'
    sel = pop(stack, variables)[0]
    return [has_element?(sel)]
  elsif cmd == 'click'
    sel = pop(stack, variables)[0]
    click(sel)
    return []
  elsif cmd == 'type'
    info = pop(stack, variables)[0]
    sel = pop(stack, variables)[0]
    # call to type
    return []
  elsif cmd == 'screenshot'
    params = pop(stack)[0]
    hsh = {}
    return ["SCREENSHOT DATA HERE params(#{params})"]
  elsif cmd == 'submit'
    # call to submit
    return []
  else
    raise UnknownCommand, "Unknown command: #{cmd}"
  end
end
