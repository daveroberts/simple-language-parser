require 'pry'
require 'json'
require './tokenizer.rb'
require './tree_parser.rb'

class NullPointer < Exception; end
class EmptyStack < Exception; end
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

def run(script, variables = {})
  tokens = tokenize(script)
  program = parse_all(tokens)
  run_block(program, variables, [])
end

def run_block(program, variables, values=[])
  stack = program.dup
  loop do
    break if stack.length == 0
    debug = stack.dup
    results = pop(stack, variables, values)
    values.concat results
  end
  return values
end

def popval(stack, variables, values)
  return pop(stack, variables, values)[0]
end

def pop(stack, variables, values)
  token = stack.shift
  if token[:type] == :int
    return [token[:value].to_i]
  elsif token[:type] == :set
    sym = stack.shift[:value]
    value = popval(stack, variables, values)
    binding.pry
    if variables.has_key? sym
      variables[sym] = value
      binding.pry
    else
      variables[sym] = value
      binding.pry
    end
    return []
  elsif token[:type] == :word
    if variables.has_key? token[:value]
      val = variables[token[:value]]
      if val.class == Hash && val[:fun]
        func = val
        debug = func
        result = func
        while stack.count > 0 && stack[0][:type] == :left_paren
          results = invoke(func, stack, variables, values)
          result = results.pop
          if result.class == Hash && result[:fun]
            func = result
          else
            break
          end
        end
        binding.pry
        return [result]
      else
        return [val]
      end
    else
      raise Exception, "#{token[:value]} undefined"
    end
  elsif token[:type] == :push
    stack.shift # left paren
    collection = popval(stack, variables, values)
    stack.shift # comma
    value = popval(stack, variables, values)
    stack.shift #right paren
    collection.push(value)
    return [collection]
  elsif token[:type] == :foreach
    sym = stack.shift[:value]
    stack.shift # in
    collection = popval(stack, variables, values)
    block = popval(stack, variables, values)
    locals = variables.dup
    collection.each do |item|
      locals[sym] = item
      run_block(block.dup, locals, [])
    end
    return []
  elsif token[:type] == :loop
    block = popval(stack, variables, values)
    locals = variables.dup
    loop do
      begin
        run_block(block.dup, variables, values)
      rescue Break
        break
      end
    end
    return []
  elsif token[:type] == :while
    cond_block = []
    loop do
      break if stack[0][:type] == :left_paren
      cond_block.push stack.shift
    end
    block = popval(stack, variables, values)
    locals = variables.dup
    loop do
      begin
        result = run_block(cond_block.dup, locals, values)[0]
        break if !result
        run_block(block.dup, locals, values)
      rescue Break
        break
      end
    end
    return []
  elsif token[:type] == :break
    raise Break
  elsif token[:type] == :return
    value = popval(stack, variables, values)
    raise Return.new(value)
  elsif token[:type] == :print
    item = popval(stack, variables, values)
    puts item
    return []
  elsif token[:type] == :plus
    val1 = popval(stack, variables, values)
    val2 = popval(stack, variables, values)
    return [val1 + val2]
  elsif token[:type] == :join
    collection = popval(stack, variables, values)
    return [collection.join()]
  elsif token[:type] == :map
    stack.shift # left paren
    collection = popval(stack, variables, values)
    stack.shift # comma
    func = popval(stack, variables, values)
    stack.shift # right paren
    locals = variables.dup
    collection = collection.map do |item|
      locals[func[:params].first] = item
      values = run_block(func[:block], locals, [])
      values[0]
    end
    return [collection]
  elsif token[:type] == :left_curly
    block = []
    count = 1
    loop do
      sym = stack.shift
      count = count - 1 if sym[:type] == :right_curly
      count = count + 1 if sym[:type] == :left_curly
      break if count == 0
      block.push sym
    end
    if block.count > 0 && block.first[:type] == :symbol
      obj = {}
      while block.count > 0
        obj[block.shift[:value]] = popval(block, variables, values)
      end
      return [obj]
    else
      return [block]
    end
  elsif token[:type] == :left_bracket
    arr = []
    count = 1
    loop do
      sym = stack.shift
      count = count - 1 if sym[:type] == :right_bracket
      count = count + 1 if sym[:type] == :left_bracket
      break if count == 0
      stack.unshift(sym)
      value = popval(stack, variables, values)
      stack.shift if stack[0][:type] == :comma # push off comma
      arr.push(value)
    end
    return [arr]
  elsif token[:type] == :left_paren
    block = []
    count = 1
    loop do
      sym = stack.shift
      count = count - 1 if sym[:type] == :right_paren
      count = count + 1 if sym[:type] == :left_paren
      break if count == 0
      block.push sym
    end
    if stack.count > 0 && stack[0][:type] == :arrow
      stack.shift # pop off arrow
      params = block.map{|t|t[:value]}
      block = popval(stack, variables, values)
      block = block.map do |b|
        if params.include? b
          b
        elsif variables.has_key? b
          variables[b]
        else
          b
        end
      end
      return [{ fun: true, params: params, block: block }]
    else
      run_block(block, variables, [])
      return [block]
    end
  elsif token[:type] == :string
    return [token[:value][1..-2]]
  elsif token[:type] == :float
    return [token[:value]]
  else
    raise Exception, "#{token[:type]} not yet defined"
  end
end

def invoke(func, stack, variables, values)
  stack.shift # left parenthesis
  params = []
  locals = variables.dup
  # read until right parenthesis
  i = 0
  loop do
    if stack[0][:type] == :right_paren
      stack.shift
      break
    end
    value = popval(stack, locals, values)
    locals[func[:params][i]] = value
    stack.shift if stack[0][:type] == :comma
    i = i+1
  end
  results = run_block(func[:block], locals, values)
  return results
end

=begin
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
    fun = { fun: true, params: params, block: block }
    variables[name] = fun
    return [fun]
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
=end

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
