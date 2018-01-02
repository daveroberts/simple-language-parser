require "pry"

module SimpleLanguage
  class Parser
    def self.parse(tokens)
      ast, rest = make_program(tokens.dup)
      return ast
    end

    def self.make_program(tokens)
      rest = tokens
      statements = []
      while rest && rest.length > 0
        statement, rest = make_statement(rest.dup)
        if !statement
          raise Exception, "Could not make a statement" if !statement
        end
        statements.push(statement)
      end
      return statements, rest
    end

    def self.make_statement(tokens)
      tokens_orig = tokens.dup
      assignment, rest = make_assignment(tokens)
      return assignment, rest if assignment
      for_block, rest = make_for(tokens)
      return for_block, rest if for_block
      loop_block, rest = make_loop(tokens)
      return loop_block, rest if loop_block
      while_block, rest = make_while(tokens)
      return while_block, rest if while_block
      if_block, rest = make_if(tokens)
      return if_block, rest if if_block
      ternary_block, rest = make_ternary(tokens)
      return ternary_block, rest if ternary_block
      return_block, rest = make_return(tokens)
      return return_block, rest if return_block
      break_block, rest = make_break(tokens)
      return break_block, rest if break_block
      next_block, rest = make_next(tokens)
      return next_block, rest if next_block
      expr, rest = make_expression(tokens.dup)
      return expr, rest if expr
      return nil, tokens
    end

    def self.make_for(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :identifier || (rest[0][:value] != 'for' && rest[0][:value] != 'foreach')
      rest.shift # for
      raise Exception, "for requires identifier" if !rest[0] || rest[0][:type] != :identifier
      singular = rest[0][:value]
      rest.shift # singular
      raise Exception, "for requires in" if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'in'
      rest.shift # in
      plural, rest = make_expression(rest)
      raise Exception, "for requires a group" if !plural
      raise Exception, "for requires block" if !rest[0] || rest[0][:type] != :left_curly
      rest.shift # left curly
      block = []
      while rest[0] && rest[0][:type] != :right_curly
        statement, rest = make_statement(rest)
        raise Exception, "Invalid statement in for block" if !statement
        block.push(statement)
      end
      raise Exception, "For block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
      rest.shift # Right curly
      return {type: :for, symbol: singular, collection: plural, block: block}, rest
    end

    def self.make_loop(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'loop'
      rest.shift # loop
      raise Exception, "loop requires block" if !rest[0] || rest[0][:type] != :left_curly
      rest.shift # left curly
      block = []
      while rest[0] && rest[0][:type] != :right_curly
        statement, rest = make_statement(rest)
        raise Exception, "Invalid statement in loop block" if !statement
        block.push(statement)
      end
      raise Exception, "Loop block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
      rest.shift # Right curly
      return {type: :loop, block: block}, rest
    end

    def self.make_if(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'if'
      true_conditions = []
      while rest[0] && rest[0][:type] == :identifier && rest[0][:value] == 'elsif' || rest[0][:value] == 'if'
        rest.shift # if/elsif
        condition, rest = make_expression(rest)
        raise Exception, "if/elsif requires condition" if !condition
        raise Exception, "if requires block" if !rest[0] || rest[0][:type] != :left_curly
        rest.shift # left curly
        true_block = []
        while rest[0] && rest[0][:type] != :right_curly
          statement, rest = make_statement(rest)
          raise Exception, "Invalid statement in if true block" if !statement
          true_block.push(statement)
        end
        raise Exception, "Block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
        true_conditions.push({condition: condition, block: true_block})
        rest.shift # Right curly
      end
      false_block = []
      if rest[0] && rest[0][:type] == :identifier && rest[0][:value] == 'else'
        rest.shift # else
        raise Exception, "else requires block" if !rest[0] || rest[0][:type] != :left_curly
        rest.shift # left curly
        while rest[0] && rest[0][:type] != :right_curly
          statement, rest = make_statement(rest)
          raise Exception, "Invalid statement in else block" if !statement
          false_block.push(statement)
        end
        raise Exception, "Block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
        rest.shift # Right curly
      end
      return {type: :if, true_conditions: true_conditions, false_block: false_block}, rest
    end

    def self.make_while(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'while'
      rest.shift # while
      condition, rest = make_expression(rest)
      raise Exception, "while requires block" if !rest[0] || rest[0][:type] != :left_curly
      rest.shift # left curly
      block = []
      while rest[0] && rest[0][:type] != :right_curly
        statement, rest = make_statement(rest)
        raise Exception, "Invalid statement in for block" if !statement
        block.push(statement)
      end
      raise Exception, "While block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
      rest.shift # Right curly
      return {type: :while, condition: condition, block: block}, rest
    end

    def self.make_function_literal(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :left_paren
      rest.shift # (
      params = []
      while rest[0] && rest[0][:type] != :right_paren do
        raise Exception, "Function expects parameter" if !rest[0] || rest[0][:type] != :identifier
        param = rest[0][:value]
        rest.shift #param
        if !rest[0] || (rest[0][:type] != :comma && rest[0][:type] != :right_paren)
          raise Exception, "Invalid parameters to function definition"
        end
        params.push(param)
        rest.shift if rest[0] && rest[0][:type] == :comma
      end
      raise Exception, "Expected ) after function list" if !rest[0] || rest[0][:type] != :right_paren
      rest.shift # right paren
      raise Exception, "Expected -> after function list" if !rest[0] || rest[0][:type] != :arrow
      rest.shift # ->
      raise Exception, "Expected block after arrow" if !rest[0] || rest[0][:type] != :left_curly
      rest.shift # {
      block = []
      while rest[0] && rest[0][:type] != :right_curly
        statement, rest = make_statement(rest)
        raise Exception, "Invalid statement in function block" if !statement
        block.push(statement)
      end
      raise Exception, "Block must end with `}`" if !rest[0] || rest[0][:type] != :right_curly
      rest.shift # Right curly
      return {type: :function, params: params, block: block}, rest
    end

    def self.make_ternary(tokens)
      rest = tokens.dup
      condition, rest = make_expression(rest)
      return nil, tokens if !condition
      return nil, tokens if !rest[0] || rest[0][:type] != :question_mark
      rest.shift # ?
      if_true, rest = make_expression(rest)
      raise Exception, "Invalid expression after ?" if !if_true
      raise Exception, ": expected after ?" if !rest[0] || rest[0][:type] != :colon
      rest.shift # :
      if_false, rest = make_expression(rest)
      return {type: :if, true_conditions: [{ condition: condition, block: [if_true]}], false_block: [if_false]}, rest
    end

    def self.make_return(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'return'
      rest.shift #return
      expr, rest = make_expression(rest)
      raise Exception, "return must return something" if !expr
      return {type: :return, payload: expr}, rest
    end

    def self.make_break(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'break'
      rest.shift #break
      return {type: :break}, rest
    end

    def self.make_next(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :identifier || rest[0][:value] != 'next'
      rest.shift #next
      return {type: :next}, rest
    end

    def self.make_assignment(tokens)
      to, rest = make_reference(tokens.dup)
      return nil, tokens if !to
      chains, rest = make_chains(rest)
      to[:chains] = chains
      return nil, tokens if rest[0] && rest[0][:type] != :equals
      rest.shift
      from, rest = make_expression(rest.dup)
      return nil, tokens if !from
      return {type: :assign, to: to, from: from}, rest
    end

    def self.make_expression(tokens)
      rest = tokens.dup
      comp, rest = make_boolean(rest)
      return comp, rest
    end

    def self.make_boolean(tokens)
      rest = tokens.dup
      lhs, rest = make_comparison(rest)
      return nil, tokens if !lhs
      if rest[0] && rest[0][:type] == :double_pipe
        rest.shift # sym
        rhs, rest = make_boolean(rest)
        raise Exception, "Invalid boolean after ||" if !rhs
        return {type: :or, left: lhs, right: rhs},rest
      elsif rest[0] && rest[0][:type] == :double_ampersand
        rest.shift # sym
        rhs, rest = make_boolean(rest)
        raise Exception, "Invalid boolean after &&" if !rhs
        return {type: :and, left: lhs, right: rhs},rest
      else
        return lhs, rest
      end
    end

    def self.make_comparison(tokens)
      rest = tokens.dup
      lhs, rest = make_term(rest)
      return nil, tokens if !lhs
      if rest[0] && rest[0][:type] == :greater_than
        rest.shift # sym
        rhs, rest = make_comparison(rest)
        raise Exception, "Invalid comparison after >" if !rhs
        return {type: :greater_than, left: lhs, right: rhs},rest
      elsif rest[0] && rest[0][:type] == :greater_than_or_equals
        rest.shift # sym
        rhs, rest = make_comparison(rest)
        raise Exception, "Invalid comparison after >=" if !rhs
        return {type: :greater_than_or_equals, left: lhs, right: rhs},rest
      elsif rest[0] && rest[0][:type] == :less_than
        rest.shift # sym
        rhs, rest = make_comparison(rest)
        raise Exception, "Invalid comparison after <" if !rhs
        return {type: :less_than, left: lhs, right: rhs},rest
      elsif rest[0] && rest[0][:type] == :less_than_or_equals
        rest.shift # sym
        rhs, rest = make_comparison(rest)
        raise Exception, "Invalid comparison after <=" if !rhs
        return {type: :less_than_or_equals, left: lhs, right: rhs},rest
      elsif rest[0] && rest[0][:type] == :double_equals
        rest.shift # sym
        rhs, rest = make_comparison(rest)
        raise Exception, "Invalid comparison after ==" if !rhs
        return {type: :check_equality, left: lhs, right: rhs},rest
      elsif rest[0] && rest[0][:type] == :not_equals
        rest.shift # sym
        rhs, rest = make_comparison(rest)
        raise Exception, "Invalid comparison after !=" if !rhs
        return {type: :check_not_equals, left: lhs, right: rhs},rest
      end
      return lhs, rest
    end

    def self.make_term(tokens)
      rest = tokens.dup
      lhs, rest = make_factor(rest)
      return nil, tokens if !lhs
      if rest[0] && rest[0][:type] == :plus
        rest.shift #sym
        rhs, rest = make_term(rest)
        raise Exception, "Invalid after +" if !rhs
        return {type: :add, left: lhs, right: rhs},rest
      elsif rest[0] && rest[0][:type] == :minus
        rest.shift
        rhs, rest = make_term(rest.dup)
        raise Exception, "Invalid after -" if !rhs
        return {type: :subtract, left: lhs, right: rhs},rest
      else
        return lhs, rest
      end
    end

    def self.make_factor(tokens)
      rest = tokens.dup
      lhs, rest = make_terminal(rest)
      return nil, tokens if !lhs
      if rest[0] && rest[0][:type] == :multiply
        rest.shift #sym
        rhs, rest = make_factor(rest)
        raise Exception, "Invalid after *" if !rhs
        return {type: :multiply, left: lhs, right: rhs}, rest
      elsif rest[0] && rest[0][:type] == :divide
        rest.shift #sym
        rhs, rest = make_factor(rest)
        raise Exception, "Invalid after /" if !rhs
        return {type: :divide, left: lhs, right: rhs}, rest
      else
        return lhs, rest
      end
    end

    def self.make_terminal(tokens)
      rest = tokens.dup
      fun, rest = make_function_literal(rest)
      return fun, rest if fun
      if rest[0] && rest[0][:type] == :left_paren
        rest.shift # left_paren
        expr, rest = make_expression(rest)
        raise Exception, "Invalid expression after (" if !expr
        raise Exception, "`(` without `)`" if rest[0][:type] != :right_paren
        rest.shift # right paren
        return {type: :grouping, expression: expr}, rest
      end
      if rest[0] && rest[0][:type] == :identifier && rest[0][:value] == 'true'
        rest.shift
        return {type: :true}, rest
      end
      if rest[0] && rest[0][:type] == :identifier && rest[0][:value] == 'false'
        rest.shift
        return {type: :false}, rest
      end
      if rest[0] && rest[0][:type] == :identifier && rest[0][:value] == 'null'
        rest.shift
        return {type: :null}, rest
      end
      num, rest = make_number(rest)
      if num
        chains, rest = make_chains(rest)
        num[:chains] = chains
        return num, rest
      end
      reg, rest = make_regex(rest)
      if reg
        chains, rest = make_chains(rest)
        reg[:chains] = chains
        return reg, rest
      end
      str, rest = make_string(rest)
      if str
        chains, rest = make_chains(rest)
        str[:chains] = chains
        return str, rest
      end
      hash, rest = make_hash_literal(rest)
      if hash
        chains, rest = make_chains(rest)
        hash[:chains] = chains
        return hash, rest
      end
      arr, rest = make_array_literal(rest)
      if arr
        chains, rest = make_chains(rest)
        arr[:chains] = chains
        return arr, rest
      end
      sym, rest = make_symbol(rest)
      if sym
        chains, rest = make_chains(rest)
        sym[:chains] = chains
        return sym, rest
      end
      ref, rest = make_reference(rest)
      if ref
        chains, rest = make_chains(rest)
        ref[:chains] = chains
        return ref, rest
      end
      return nil, tokens
    end

    def self.make_chains(tokens)
      rest = tokens.dup
      matched_any = false
      chains = []
      while true do
        matched_any = false
        if rest[0] && rest[0][:type] == :left_bracket
          matched_any = true
          rest.shift
          ind, rest = make_expression(rest.dup)
          raise Exception, "Invalid array index" if !ind
          if !rest[0] || rest[0][:type] != :right_bracket
            raise Exception, "Left bracket without right bracket"
          end
          rest.shift
          chains.push({type: :index_of, index: ind})
        elsif rest[0] && rest[0][:type] == :left_paren
          rest.shift # left paren
          matched_any = true
          params = []
          while rest[0] && rest[0][:type] != :right_paren do
            expr, rest = make_expression(rest.dup)
            raise Exception, "Invalid parameter" if !expr
            if rest[0] && (rest[0][:type] != :comma && rest[0][:type] != :right_paren)
              raise Exception, "Invalid parameters to function call.  Exception ')' but got #{Parser.token_to_s(rest[0])}"
            end
            params.push(expr)
            rest.shift if rest[0] && rest[0][:type] == :comma
          end
          rest.shift if rest[0] && rest[0][:type] == :right_paren
          chains.push({type: :function_params, params: params})
        elsif rest[0] && rest[0][:type] == :dot
          matched_any = true
          rest.shift
          raise Exception, "Must have identifier after ." if !rest[0] || rest[0][:type] != :identifier
          member = rest[0][:value]
          rest.shift
          chains.push({type: :member, member: member})
        end
        break if !matched_any
      end
      return chains, rest
    end

    def self.make_number(tokens)
      rest = tokens.dup
      if rest[0] && rest[0][:type] == :number
        number = rest[0][:value]
        rest.shift # number
        return {type: :int, value: number}, rest
      else
        return nil, tokens
      end
    end

    def self.make_regex(tokens)
      rest = tokens.dup
      if rest[0] && rest[0][:type] == :regex
        value = rest[0][:value]
        rest.shift # regex
        return {type: :regex, value: value}, rest
      else
        return nil, tokens
      end
    end

    def self.make_string(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :string
      str = rest[0][:value]
      rest.shift
      return {type: :string, value: str}, rest
    end

    def self.make_symbol(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :symbol
      sym = rest[0][:value].to_sym
      rest.shift
      return {type: :symbol, value: sym}, rest
    end

    def self.make_hash_literal(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :left_curly
      rest.shift #left curly
      objects = {}
      while rest[0] && rest[0][:type] != :right_curly
        raise Exception, "Expected symbol, got #{Parser.token_to_s(rest[0])}" if rest[0][:type] != :symbol
        symbol = rest[0][:value]
        symbol = symbol.to_sym
        rest.shift
        rhs, rest = make_expression(rest)
        raise Exception, "Invalid hash map value" if !rhs
        objects[symbol] = rhs
        rest.shift if rest[0] && rest[0][:type] == :comma
      end
      rest.shift # right curly
      return { type: :hashmap, objects: objects }, rest
    end

    def self.make_array_literal(tokens)
      rest = tokens.dup
      return nil, tokens if !rest[0] || rest[0][:type] != :left_bracket
      rest.shift #left bracket
      items = []
      while rest[0] && rest[0][:type] != :right_bracket
        item, rest = make_expression(rest)
        raise Exception, "Invalid array item" if !item
        items.push(item)
        rest.shift if rest[0] && rest[0][:type] == :comma
      end
      rest.shift # right bracket
      return { type: :array, items: items }, rest
    end

    def self.make_reference(tokens)
      if !tokens[0] || tokens[0][:type] != :identifier
        return nil, tokens
      end
      ident = tokens[0][:value]
      tokens.shift
      rest = tokens.dup
      return {type: :reference, value: ident }, rest
    end
    
    def self.token_to_s(cmd)
      if cmd[:type] == :identifier
        return "`#{cmd[:value]}`"
      else
        binding.pry
      end
    end
  end
end
