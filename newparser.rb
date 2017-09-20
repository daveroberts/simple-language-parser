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
  run_block(program, variables)
end

def run_block(program, variables)
  stack = program.dup
  output = nil
  stack.each do |command|
    output = exec_cmd(command, variables)
  end
  return output
end

def exec_cmd(command, variables)
  if command[:type] == :set
    if command[:symbol][:type] == :word
      variables[command[:symbol][:value]] = exec_cmd(command[:value], variables)
      return nil
    elsif command[:symbol][:type] == :index_of
      variables[command[:symbol][:symbol]][exec_cmd(command[:symbol][:index], variables)] = exec_cmd(command[:value], variables)
    else
      binding.pry # set on something other than a word
    end
  elsif command[:type] == :add_apply
    left = exec_cmd(command[:left], variables)
    right = exec_cmd(command[:right], variables)
    return left + right
  elsif command[:type] == :mult_apply
    left = exec_cmd(command[:left], variables)
    right = exec_cmd(command[:right], variables)
    return left * right
  elsif command[:type] == :call
    fun_name = command[:fun]
    if is_system_command? fun_name
      return run_system_command(fun_name, command[:arguments], variables)
    else
      raise NullPointer, "#{fun_name} does not exist" if !variables.has_key? fun_name
      fun = variables[fun_name]
      command[:arguments].each_with_index do |arg, i|
        variables[fun[:params][i][:value]] = exec_cmd(arg, variables)
      end
      output = run_block(fun[:block], variables)
      return output
    end
  elsif command[:type] == :int
    return command[:value].to_i
  elsif command[:type] == :word #:get_value
    raise NullPointer, "#{command[:value]} does not exist" if !variables.has_key? command[:value]
    return variables[command[:value]]
  elsif command[:type] == :function
    return {
      type: :function,
      params: command[:params],
      block: command[:block]
    }
  elsif command[:type] == :foreach_apply
    collection = run_block(command[:collection], variables)
    symbol = command[:symbol]
    block = command[:block]
    locals = variables.dup
    collection.each do |item|
      locals[symbol] = item
      run_block(block, locals)
    end
  elsif command[:type] == :while_apply
    condition = command[:condition]
    block = command[:block]
    while exec_cmd(condition,variables) do
      run_block(block,variables)
    end
  elsif command[:type] == :loop_apply
    block = command[:block]
    loop do
      begin
        run_block(block, variables)
      rescue Break
        break
      end
    end
  elsif command[:type] == :break
    raise Break
  elsif command[:type] == :array
    arr = command[:items].map{|i|run_block(i,variables)}
    return arr
  elsif command[:type] == :index_of
    return variables[command[:symbol]][exec_cmd(command[:index], variables)]
  elsif command[:type] == :string
    return command[:value][1..-2]
  elsif command[:type] == :check_equality
    left = exec_cmd(command[:left], variables)
    right = exec_cmd(command[:right], variables)
    return left == right
  elsif command[:type] == :symbol
    return command[:value]
  elsif command[:type] == :hashmap
    obj = {}
    command[:objects].each do |o|
      obj[o[:symbol]] = run_block(o[:block], variables)
    end
    return obj
  else
    puts command
    raise Exception, "unhandled command type: #{command[:type]}"
  end
end

def is_system_command?(fun)
  system_cmds = ['print','join','push']
  return system_cmds.include? fun
end

def run_system_command(fun, args, variables)
  case fun
  when "print"
    puts(run_block(args, variables))
  when "join"
    return run_block(args, variables).join
  when "push"
    collection = exec_cmd(args[0], variables)
    item = exec_cmd(args[1], variables)
    collection.push item
  else
    raise Exception, "system call '#{fun}' not implemented"
  end
end
