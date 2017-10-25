require 'pry'
require 'json'
require_relative './tokenizer.rb'
require_relative './parser.rb'

module SimpleLanguage
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

  class Executor
    def initialize
      @external_commands = {}
    end

    def register(name, instance, function)
      @external_commands[name] = {
        instance: instance,
        function: function
      }
    end

    def run(script)
      tokens = SimpleLanguage::Tokenizer.new.tokenize(script)
      program = SimpleLanguage::Parser.new.parse(tokens)
      run_block(program, {})
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
      elsif command[:type] == :minus_apply
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left - right
      elsif command[:type] == :mult_apply
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left * right
      elsif command[:type] == :call
        fun_name = command[:fun]
        if is_system_command? fun_name
          return run_system_command(fun_name, command[:arguments], variables)
        elsif is_external_command? fun_name
          return run_external_command(fun_name, command[:arguments], variables)
        else
          fun = nil
          if fun_name.class == String
            raise NullPointer, "#{fun_name} does not exist" if !variables.has_key? fun_name
            fun = variables[fun_name]
          else
            fun = exec_cmd(fun_name, variables)
          end
          locals = variables.dup
          command[:arguments].each_with_index do |arg, i|
            locals[fun[:params][i][:value]] = exec_cmd(arg, locals)
          end
          output = nil
          locals = fun[:locals].merge(locals)
          begin
            output = run_block(fun[:block], locals)
          rescue Return => ret
            output = ret.value
          end
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
          block: command[:block],
          locals: variables.dup
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
      elsif command[:type] == :if_apply
        command[:true_conditions].each do |cond|
          predicate = exec_cmd(cond[:condition], variables)
          if predicate
            return run_block(cond[:block], variables)
            break
          end
        end
        return run_block(command[:false_block], variables)
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
      elsif command[:type] == :return_apply
        raise Return.new(exec_cmd(command[:value], variables))
      elsif command[:type] == :null
        return nil
      elsif command[:type] == :true
        return true
      elsif command[:type] == :false
        return false
      elsif command[:type] == :array
        arr = command[:items].map{|i|run_block(i,variables)}
        return arr
      elsif command[:type] == :index_of
        if command.has_key? :symbol
          return variables[command[:symbol]][exec_cmd(command[:index], variables)]
        else
          arr = exec_cmd(command[:obj_or_array], variables)
          return arr[exec_cmd(command[:index], variables)]
        end
      elsif command[:type] == :string
        return command[:value][1..-2]
      elsif command[:type] == :check_equality
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left == right
      elsif command[:type] == :check_less_than_or_equals
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left <= right
      elsif command[:type] == :check_greater_than_or_equals
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left >= right
      elsif command[:type] == :check_less_than
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left < right
      elsif command[:type] == :check_greater_than
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left > right
      elsif command[:type] == :check_not_equality
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left != right
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
      system_cmds = ['print','join','push','map','len']
      return system_cmds.include? fun
    end

    def run_system_command(fun, args, variables)
      case fun
      when "print"
        puts(run_block(args, variables))
      when "join"
        return run_block(args, variables).join
      when "len"
        return exec_cmd(args[0], variables).length
      when "map"
        collection = exec_cmd(args[0], variables)
        fun = nil
        fun_name = exec_cmd(args[1], variables)
        if fun_name.class == String
          raise NullPointer, "#{fun_name} does not exist" if !variables.has_key? fun_name
          fun = variables[fun_name]
        else
          fun = exec_cmd(fun_name, variables)
        end
        locals = variables.dup
        output = nil
        locals = fun[:locals].merge(locals)
        arr = []
        collection.each do |item|
          locals[fun[:params][0][:value]] = item
          begin
            output = run_block(fun[:block], locals)
          rescue Return => ret
            output = ret.value
          end
          arr.push output
        end
        return arr
      when "push"
        collection = exec_cmd(args[0], variables)
        item = exec_cmd(args[1], variables)
        collection.push item
      else
        raise Exception, "system call '#{fun}' not implemented"
      end
    end

    def is_external_command?(fun)
      return @external_commands.has_key? fun
    end

    def run_external_command(fun, args, variables)
      arr = []
      args.each do |arg|
        arr.push(exec_cmd(arg, variables))
      end
      return @external_commands[fun][:instance].send(@external_commands[fun][:function], *arr)
    end
  end
end
