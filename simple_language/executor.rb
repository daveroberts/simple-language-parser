require 'pry'
require 'json'
require 'securerandom'
require 'digest'
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
  class Next < Exception; end
  class Return < Exception
    attr_reader :value
    def initialize(v)
      @value = v
    end
  end

  class Executor
    def initialize
      @external = {
        functions: {},
        values: {}
      }
    end

    def register_function(name, instance, function)
      @external[:functions][name] = {
        instance: instance,
        function: function
      }
    end

    def register_external_value(name, value)
      @external[:values][name] = value
    end

    def run(script, input = nil, trace = [])
      @input = input
      @trace = trace
      tokens = Tokenizer.lex(script)
      ast = Parser.parse(tokens)
      begin
        run_block(ast, {})
      rescue Return => ret
        return ret.value
      end
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
      if command[:type] == :assign
        value = exec_cmd(command[:from], variables)
        to = nil
        if command[:to][:type] == :reference
          if command[:to][:chains].length == 0
            variables[command[:to][:value]] = value
            if value && value.class == Hash && value.has_key?(:type)
              @trace.push({ summary: "Assigning #{Executor.cmd_to_s(value)} to #{command[:to][:value]}", level: :debug, timestamp: Time.now })
            else
              if value.class != String || value.valid_encoding?
                @trace.push({ summary: "Assigning #{value} to #{command[:to][:value]}", level: :debug, timestamp: Time.now })
              else
                @trace.push({ summary: "Assigning binary data to #{command[:to][:value]}", level: :debug, timestamp: Time.now })
              end
            end
          else
            ref = variables[command[:to][:value]]
            chains = command[:to][:chains].dup
            while chains.length > 1
              chain = chains.first
              if chain[:type] == :index_of
                index = exec_cmd(chain[:index], variables)
                ref = ref[index]
                chains.shift
              else
                binding.pry # chain on non-index_of
              end
            end
            if chains.length > 0
              chain = chains.first
              if chain[:type] == :index_of
                index = exec_cmd(chain[:index], variables)
                ref[index] = value
                @trace.push({ summary: "Assigning #{value} to index #{index}", level: :debug, timestamp: Time.now })
              elsif chain[:type] == :member
                binding.pry #todo
              else
                binding.pry #what kind of chain is this?
              end
            else
              ref = value
            end
          end
        else
          binding.pry # assign to what?
        end
      elsif command[:type] == :add
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        @trace.push({ summary: "Adding #{left} and #{right}", level: :debug, timestamp: Time.now })
        return left + right
      elsif command[:type] == :subtract
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        @trace.push({ summary: "Subtracting #{right} from #{left}", level: :debug, timestamp: Time.now })
        return left - right
      elsif command[:type] == :multiply
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        @trace.push({ summary: "Multiplying #{left} and #{right}", level: :debug, timestamp: Time.now })
        return left * right
      elsif command[:type] == :int
        val = command[:value].to_i
        output = run_chains(val, command[:chains]||[], variables)
        return output
      elsif command[:type] == :regex
        value = command[:value]
        match = /^\/(.*)\/(.*)$/.match(value)
        reg_str = match[1]
        opt_str = match[2]
        opts = 0
        opts = opts | Regexp::IGNORECASE if opt_str.include? "i"
        opts = opts | Regexp::MULTILINE if opt_str.include? "m"
        regex = Regexp.new(reg_str, opts)
        output = run_chains(regex, command[:chains]||[], variables)
        @trace.push({ summary: "Regex matching: Regex #{reg_str} matches #{output}", level: :debug, timestamp: Time.now })
        return output
      elsif command[:type] == :reference #:get_value
        name = command[:value]
        ref = nil
        chains = command[:chains].dup
        # check if system command
        if is_system_command? name
          raise InvalidParameter, "You must pass arguments to a system command" if chains.length == 0 || chains.first[:type] != :function_params
          params = chains.first[:params]
          params = params.map{|p|exec_cmd(p, variables)}
          ref = run_system_command(name, params, variables)
          chains.shift
        elsif is_external_value? name
          ref = get_external_value(name)
        elsif is_external_function? name
          raise InvalidParameter, "You must pass arguments to an external command" if chains.length == 0 || chains.first[:type] != :function_params
          params = chains.first[:params]
          params = params.map{|p|exec_cmd(p, variables)}
          ref = run_external_function(name, params)
          chains.shift
        else
          raise NullPointer, "#{command[:value]} does not exist" if !variables.has_key? command[:value]
          ref = variables[command[:value]]
        end
        output = run_chains(ref, chains, variables)
        return output
      elsif command[:type] == :function
        return {
          type: :function,
          params: command[:params],
          block: command[:block],
          locals: variables.dup
        }
      elsif command[:type] == :for
        collection = exec_cmd(command[:collection], variables)
        symbol = command[:symbol]
        block = command[:block]
        #locals = variables.dup
        #TODO: outer variables should be altered, inner no
        @trace.push({ summary: "Running for loop on #{collection.length} items", level: :debug, timestamp: Time.now })
        collection.each do |item|
          @trace.push({ summary: "Current item: #{item}", level: :debug, timestamp: Time.now })
          variables[symbol] = item
          begin
            run_block(block, variables)
          rescue Next
            next
          rescue Break
            break
          end
        end
      elsif command[:type] == :while
        @trace.push({ summary: "Starting while loop", level: :debug, timestamp: Time.now })
        condition = command[:condition]
        block = command[:block]
        while exec_cmd(condition,variables) do
          run_block(block,variables)
        end
      elsif command[:type] == :if
        @trace.push({ summary: "Starting if block", level: :debug, timestamp: Time.now })
        command[:true_conditions].each do |cond|
          predicate = exec_cmd(cond[:condition], variables)
          if predicate
            @trace.push({ summary: "If condition true: #{Executor.cmd_to_s(cond[:condition])}", level: :debug, timestamp: Time.now })
            return run_block(cond[:block], variables)
            break
          else
            @trace.push({ summary: "If condition false: #{Executor.cmd_to_s(cond[:condition])}", level: :debug, timestamp: Time.now })
          end
        end
        @trace.push({ summary: "If matched no conditions, running false block", level: :debug, timestamp: Time.now })
        return run_block(command[:false_block], variables)
      elsif command[:type] == :loop
        @trace.push({ summary: "Starting loop", level: :debug, timestamp: Time.now })
        block = command[:block]
        loop do
          begin
            run_block(block, variables)
          rescue Break
            @trace.push({ summary: "Breaking from loop", level: :debug, timestamp: Time.now })
            break
          rescue Next
            @trace.push({ summary: "Next called on loop", level: :debug, timestamp: Time.now })
            next
          end
        end
      elsif command[:type] == :break
        raise Break
      elsif command[:type] == :next
        raise Next
      elsif command[:type] == :return
        value = exec_cmd(command[:payload], variables)
        @trace.push({ summary: "Returning #{value}", level: :debug, timestamp: Time.now })
        raise Return.new(value)
      elsif command[:type] == :null
        return nil
      elsif command[:type] == :true
        return true
      elsif command[:type] == :false
        return false
      elsif command[:type] == :array
        arr = command[:items].map{|i|exec_cmd(i,variables)}
        output = run_chains(arr, command[:chains]||[], variables)
        @trace.push({ summary: "Created array", level: :debug, timestamp: Time.now })
        return output
      elsif command[:type] == :index_of
        if command.has_key? :symbol
          return variables[command[:symbol]][exec_cmd(command[:index], variables)]
        else
          arr = exec_cmd(command[:obj_or_array], variables)
          return arr[exec_cmd(command[:index], variables)]
        end
      elsif command[:type] == :string
        val = command[:value]
        output = run_chains(val, command[:chains]||[], variables)
        return output
      elsif command[:type] == :check_equality
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left == right
      elsif command[:type] == :less_than_or_equals
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left <= right
      elsif command[:type] == :greater_than_or_equals
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left >= right
      elsif command[:type] == :less_than
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left < right
      elsif command[:type] == :greater_than
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left > right
      elsif command[:type] == :check_not_equals
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left != right
      elsif command[:type] == :or
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left || right
       elsif command[:type] == :and
        left = exec_cmd(command[:left], variables)
        right = exec_cmd(command[:right], variables)
        return left && right
      elsif command[:type] == :symbol
        val = command[:value]
        output = run_chains(val, command[:chains]||[], variables)
        return output
      elsif command[:type] == :hashmap
        obj = {}
        command[:objects].each do |key, value|
          obj[key] = exec_cmd(value, variables)
        end
        output = run_chains(obj, command[:chains]||[], variables)
        return output
      else
        puts command
        raise UnknownCommand, "Unknown command type: #{command[:type]}"
      end
    end

    def run_chains(ref, orig_chains, variables)
      chains = orig_chains.dup
      while chains.length > 0 do
        chain = chains.first
        chains.shift
        if chain[:type] == :index_of
          index = exec_cmd(chain[:index], variables)
          ref = ref[index]
        elsif chain[:type] == :function_params
          if ref.class == Hash &&
             ref.has_key?(:type) &&
             ref[:type] == :function
            locals = variables.dup
            chain[:params].each_with_index do |param, i|
              locals[ref[:params][i]] = exec_cmd(param, locals)
            end
            output = nil
            begin
              output = run_block(ref[:block], locals)
            rescue Return => ret
              output = ret.value
            end
            @trace.push({ summary: "function(#{ref[:params].join(",")}) returned #{output}", level: :debug, timestamp: Time.now })
            ref = output
          else
            raise "`#{ref.class.to_s}` is not a function"
          end
        elsif chain[:type] == :member
          member = chain[:member]
          params = []
          locals = variables.dup
          if chains.length > 0 && chains[0][:type] == :function_params
            params = chains[0][:params].map{|p|exec_cmd(p, locals)}
            chains.shift
          end
          ref = ref.send(member, *params)
        else
          binding.pry #todo?
        end
      end
      return ref
    end

      def is_system_command?(fun)
      system_cmds = ['print','join','push','map','filter','len','md5','sha512','random', 'uuid', 'input',"int", "now", "match"]
      return system_cmds.include? fun
    end

    def run_system_command(fun, args, variables)
      case fun
      when "print"
        args.each do |arg|
          @trace.push({ summary: arg, level: :info, timestamp: Time.now })
        end
        puts(*args)
      when "join"
        @trace.push({ summary: "Joining: #{args[0]}", level: :debug, timestamp: Time.now })
        return args[0].join(args[1])
      when "len"
        @trace.push({ summary: "Length of #{args[0]}} is #{args[0].length}", level: :debug, timestamp: Time.now })
        return args[0].length
      when "md5"
        value = Digest::MD5.hexdigest(args[0])
        @trace.push({ summary: "MD5 of #{args[0]} is #{value}", level: :debug, timestamp: Time.now })
        return value
      when "sha512"
        value = Digest::SHA512.hexdigest(args[0])
        @trace.push({ summary: "SHA512 of #{args[0]} is #{value}", level: :debug, timestamp: Time.now })
        return value
      when "uuid"
        value = SecureRandom.uuid
        @trace.push({ summary: "Generated UUID of #{value}", level: :debug, timestamp: Time.now })
        return value
      when "now"
        return Time.new
      when "map"
        collection = args[0]
        fun = args[1]
        locals = variables.dup
        arr = []
        collection.each do |item|
          locals[fun[:params][0]] = item
          output = nil
          begin
            output = run_block(fun[:block], locals)
          rescue Return => ret
            output = ret.value
          end
          arr.push(output)
        end
        return arr
      when "match"
        regex_str = args[0]
        str = args[1]
        match = nil
        if regex_str.start_with? "/"
          parts = /\/(.*)\/(.*)/.match(regex_str)
          regex_str = parts[1]
          opts_str = parts[2]
          opts = 0
          opts = opts | Regexp::IGNORECASE if opts_str.include? "i"
          opts = opts | Regexp::MULTILINE if opts_str.include? "m"
          opts = opts | Regexp::EXTENDED if opts_str.include? "x"
          match = Regexp.new(regex_str, opts).match(str)
        else
          match = Regexp.new(regex_str).match(str)
        end
        return nil if !match
        return match.to_a
      when "filter"
        collection = args[0]
        fun = args[1]
        locals = variables.dup
        arr = []
        collection.each do |item|
          locals[fun[:params][0]] = item
          output = nil
          begin
            output = run_block(fun[:block], locals)
          rescue Return => ret
            output = ret.value
          end
          arr.push(item) if output
        end
        @trace.push({ summary: "Filtered #{arr.length} out of #{collection.length}", level: :info, tables: [{
          title: "Matched",
          headers: [
            { name: "Item", type: "string" }
          ],
          rows: arr.map{|item| [{ value: item }] }
        },{
          title: "All",
          headers: [
            { name: "Item", type: "string" }
          ],
          rows: collection.map{|item| [{ value: item }] }
        }],
        show_tables: false,
        timestamp: Time.now })
        return arr
      when "push"
        collection = args[0]
        item = args[1]
        collection.push item
      when "random"
        a = args[0]
        b = args[1]
        return Random.rand(a..b)
      when "input"
        return @input
      when "int"
        x = args[0]
        return x.to_i
      else
        raise Exception, "system call '#{fun}' not implemented"
      end
    end

    def is_external_function?(fun)
      return @external[:functions].has_key? fun
    end

    def run_external_function(fun, args)
      return @external[:functions][fun][:instance].send(@external[:functions][fun][:function], *args)
    end

    def is_external_value?(name)
      return @external[:values].has_key? name
    end

    def get_external_value(name)
      return @external[:values][name]
    end

    def self.cmd_to_s(cmd)
      if cmd[:type] == :check_equality
        return "#{cmd_to_s(cmd[:left])} == #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :function
        return "function"
      elsif cmd[:type] == :reference
        return cmd[:value]
      elsif cmd[:type] == :int
        return cmd[:value]
      elsif cmd[:type] == :less_than_or_equals
        return "#{cmd_to_s(cmd[:left])} <= #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :greater_than_or_equals
        return "#{cmd_to_s(cmd[:left])} >= #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :less_than
        return "#{cmd_to_s(cmd[:left])} < #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :greater_than
        return "#{cmd_to_s(cmd[:left])} > #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :check_not_equals
        return "#{cmd_to_s(cmd[:left])} != #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :or
        return "#{cmd_to_s(cmd[:left])} || #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :and
        return "#{cmd_to_s(cmd[:left])} && #{cmd_to_s(cmd[:right])}"
      elsif cmd[:type] == :true
        return "true"
      elsif cmd[:type] == :false
        return "false"
      elsif cmd[:type] == :identifier
        return cmd[:value]
      elsif cmd[:type] == :null
        return "null"
      else
        binding.pry
      end
    end
  end
end
