require 'pry'

def parse_all(tokens)
  program = parse(tokens)
  binding.pry
  return program
end

def parse(tokens)
  tokens = parse_array(tokens)
  tokens = parse_functions(tokens)
  tokens = parse_multiply(tokens)
  tokens = parse_add(tokens)
  tokens = parse_double_equals(tokens)
  tokens = parse_hashmaps(tokens)
  tokens = parse_index(tokens)
  tokens = parse_invoke(tokens)
  tokens = parse_variables(tokens)
  tokens = parse_set(tokens)
  tokens = parse_while(tokens)
  tokens = parse_loop(tokens)
  tokens = parse_foreach(tokens)
  return tokens
end

def parse_invoke(tokens)
  orig_tokens = tokens.dup
  tokens = tokens.dup
  i = 0
  loop do
    break if i >= tokens.count - 1
    token = tokens[i]
    next_token = tokens[i+1]
    i = i+1
    next if token[:type] != :word
    next if next_token[:type] != :left_paren
    # We have an invocation
    i = i - 1
    fun = token[:value]
    tokens.delete_at(i)
    tokens.delete_at(i)
    arguments = []
    paren_count = 1
    current_argument = []
    loop do
      binding.pry if tokens[i] == nil
      paren_count = paren_count - 1 if tokens[i][:type] == :right_paren
      paren_count = paren_count + 1 if tokens[i][:type] == :left_paren
      break if paren_count == 0
      if tokens[i][:type] == :comma && paren_count == 1
        arguments.push(current_argument)
        current_argument = []
      else
        current_argument.push(tokens[i])
      end
      tokens.delete_at(i)
    end
    tokens.delete_at(i)
    arguments.push(current_argument)
    arguments = arguments.map{|a|parse(a)}
    cmd = { type: :call, fun: fun, arguments: arguments }
    tokens.insert(i, cmd)
  end
  return tokens
end

def parse_functions(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:arrow}) do
    params = []
    offset = 1
    tokens.delete_at(index-offset) # right paren
    loop do
      offset = offset + 1
      params.unshift tokens[index-offset]
      tokens.delete_at(index-offset)
      offset = offset + 1
      break if tokens[index-offset][:type] == :left_paren
      tokens.delete_at(index-offset)
    end
    tokens.delete_at(index-offset) # delete left paren
    index = index-offset
    tokens.delete_at(index) # arrow
    block = []
    count = 1
    tokens.delete_at(index) # delete left curly
    loop do
      count = count - 1 if tokens[index][:type] == :right_curly
      count = count + 1 if tokens[index][:type] == :left_curly
      break if count == 0
      block.push tokens[index]
      tokens.delete_at index
    end
    tokens.delete_at index # delete right curly
    commands = parse(block)
    cmd = { type: :function, params: params, block: commands }
    tokens.insert(index, cmd)
  end
  return tokens
end

def parse_multiply(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:multiply}) do
    left = tokens[index-1]
    right = tokens[index+1]
    cmd = { type: :mult_apply, left: left, right: right }
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.insert(index-1, cmd)
  end
  return tokens
end

def parse_add(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:plus}) do
    left = tokens[index-1]
    right = tokens[index+1]
    cmd = { type: :add_apply, left: left, right: right }
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.insert(index-1, cmd)
  end
  return tokens
end

def parse_set(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:equals}) do
    left = tokens[index-1]
    right = tokens[index+1]
    cmd = { type: :set, symbol: left, value: right }
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.insert(index-1, cmd)
  end
  return tokens
end

def parse_while(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:while}) do
    tokens.delete_at index # remove while
    condition = tokens[index]
    tokens.delete_at index # remove condition
    tokens.delete_at index # remove left curly
    block = []
    count = 1
    loop do
      count = count - 1 if tokens[index][:type] == :right_curly
      count = count + 1 if tokens[index][:type] == :left_curly
      break if count == 0
      block.push tokens[index]
      tokens.delete_at index
    end
    tokens.delete_at index # right_curly
    cmd = { type: :while_apply, condition: condition, block: parse(block) }
    tokens.insert(index, cmd)
  end
  return tokens
end

def parse_double_equals(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:double_equals}) do
    left = tokens[index-1]
    right = tokens[index+1]
    cmd = { type: :check_equality, left: left, right: right }
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.delete_at(index-1)
    tokens.insert(index-1, cmd)
  end
  return tokens
end

def parse_hashmaps(tokens)
  tokens = tokens.dup
  i = 0
  loop do
    break if i >= tokens.count - 1
    token = tokens[i]
    next_token = tokens[i+1]
    i = i+1
    next if token[:type] != :left_curly
    next if next_token[:type] != :symbol
    # We have a hashmap
    i = i - 1
    all_objects = []
    tokens.delete_at(i) # left_curly
    current_obj = {symbol: nil, block: []}
    count = 1
    loop do
      count = count - 1 if tokens[i][:type] == :right_curly
      count = count + 1 if tokens[i][:type] == :left_curly
      break if count == 0
      if tokens[i][:type] == :comma && count == 1
        all_objects.push(current_obj)
        current_obj = { symbol: nil, block: [] }
      else
        if current_obj[:symbol] == nil
          current_obj[:symbol] = tokens[i][:value]
        else
          current_obj[:block].push tokens[i]
        end
      end
      tokens.delete_at(i)
    end
    tokens.delete_at(i) # right_curly
    all_objects.push(current_obj)
    all_objects = all_objects.map do |o|
      o[:block] = parse(o[:block])
      o
    end
    cmd = { type: :hashmap, objects: all_objects }
    tokens.insert(i, cmd)
  end
  return tokens
end

def parse_index(tokens)
  tokens = tokens.dup
  i = 0
  loop do
    break if i >= tokens.count - 1
    token = tokens[i]
    next_token = tokens[i+1]
    i = i+1
    next if token[:type] != :word
    next if next_token[:type] != :left_bracket
    # We have an index
    i = i - 1
    symbol = token[:value]
    tokens.delete_at(i) # word
    tokens.delete_at(i) # left_bracket
    count = 1
    block = []
    loop do
      count = count - 1 if tokens[i][:type] == :right_bracket
      count = count + 1 if tokens[i][:type] == :left_bracket
      break if count == 0
      block.push tokens[i]
      tokens.delete_at(i)
    end
    tokens.delete_at(i) # right_bracket
    block = parse(block)
    cmd = { type: :index_of, symbol: symbol, block: block }
    tokens.insert(i, cmd)
  end
  return tokens
end

def parse_array(tokens)
  tokens = tokens.dup
  i = 0
  loop do
    break if i >= tokens.count
    token = tokens[i]
    i = i + 1
    next if token[:type] != :left_bracket
    next if i > 0 && tokens[i-1][:type] == :word # index not array
    # We have an array
    all_items = []
    i = i - 1
    tokens.delete_at(i) # left_bracket
    current_item = []
    count = 1
    loop do
      count = count - 1 if tokens[i][:type] == :right_bracket
      count = count + 1 if tokens[i][:type] == :left_bracket
      break if count == 0
      if tokens[i][:type] == :comma && count == 1
        all_items.push(current_item)
        current_item = []
      else
        current_item.push tokens[i]
      end
      tokens.delete_at(i)
    end
    tokens.delete_at(i) # right_bracket
    all_items.push(current_item) if current_item.count > 0
    all_items = all_items.map do |item|
      item = parse(item)
      item
    end
    cmd = { type: :array, items: all_items }
    tokens.insert(i, cmd)
  end
  return tokens
end

def parse_loop(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:loop}) do
    tokens.delete_at index # remove loop
    tokens.delete_at index # remove left curly
    block = []
    count = 1
    loop do
      count = count - 1 if tokens[index][:type] == :right_curly
      count = count + 1 if tokens[index][:type] == :left_curly
      break if count == 0
      block.push tokens[index]
      tokens.delete_at index
    end
    tokens.delete_at index # right_curly
    cmd = { type: :loop_apply, block: parse(block) }
    tokens.insert(index, cmd)
  end
  return tokens
end

def parse_foreach(tokens)
  tokens = tokens.dup
  while(index = tokens.find_index{|t|t[:type]==:foreach}) do
    tokens.delete_at index # remove foreach
    symbol = tokens[index]
    tokens.delete_at index # remove symbol
    tokens.delete_at index # remove in
    collection = []
    loop do
      break if tokens[index][:type] == :left_curly
      collection.push tokens[index]
      tokens.delete_at index
    end
    tokens.delete_at index # left_curly
    block = []
    count = 1
    loop do
      count = count - 1 if tokens[index][:type] == :right_curly
      count = count + 1 if tokens[index][:type] == :left_curly
      break if count == 0
      block.push tokens[index]
      tokens.delete_at index
    end
    tokens.delete_at index # right_curly
    cmd = { type: :foreach_apply, collection: parse(collection), block: parse(block) }
    tokens.insert(index, cmd)
  end
  return tokens
end

def parse_variables(tokens)
  tokens = tokens.dup
  tokens = tokens.map do |token|
    if token[:type] == :word
      { type: :get_value, symbol: token[:value] }
    else
      token
    end
  end
  return tokens
end
